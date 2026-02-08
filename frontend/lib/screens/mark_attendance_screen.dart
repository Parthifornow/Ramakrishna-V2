import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';
import '../models/attendance_model.dart';
import '../services/api_service.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final User user;
  final AssignedClass assignedClass;

  const MarkAttendanceScreen({
    Key? key,
    required this.user,
    required this.assignedClass,
  }) : super(key: key);

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  List<Student> students = [];
  Map<String, String> attendanceStatus = {};
  bool isLoading = true;
  bool isSaving = false;
  DateTime selectedDate = DateTime.now();
  String? selectedSubject;
  String? selectedPeriod;
  List<String> subjects = [];
  final List<String> periods = ['1', '2', '3', '4', '5', '6', '7', '8'];

  @override
  void initState() {
    super.initState();
    _initializeSubjects();
    _loadStudents();
  }

  void _initializeSubjects() {
    // Get subjects from user data
    if (widget.user.subjects != null && widget.user.subjects!.isNotEmpty) {
      subjects = widget.user.subjects!;
      selectedSubject = subjects.first;
    } else {
      subjects = ['General'];
      selectedSubject = 'General';
    }
  }

  Future<void> _loadStudents() async {
    setState(() => isLoading = true);

    try {
      final studentsResult = await ApiService.getMyClassStudents(
        token: widget.user.token!,
        classId: widget.assignedClass.classId,
      );

      if (studentsResult['success']) {
        final data = studentsResult['data'];
        final List<dynamic> studentsData = data['students'] ?? [];
        
        setState(() {
          students = studentsData.map((s) => Student.fromJson(s)).toList();
          
          // Initialize all as absent
          for (var student in students) {
            attendanceStatus[student.id] = 'absent';
          }
        });

        // Check for existing attendance
        if (selectedSubject != null) {
          await _loadExistingAttendance();
        }
      }
    } catch (e) {
      print('Error loading students: $e');
      _showErrorSnackbar('Failed to load students');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadExistingAttendance() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    
    try {
      final result = await ApiService.getClassAttendance(
        token: widget.user.token!,
        classId: widget.assignedClass.classId,
        date: dateStr,
        subject: selectedSubject,
        period: selectedPeriod,
      );

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        final List<dynamic> attendanceList = data['attendance'] ?? [];
        
        setState(() {
          for (var record in attendanceList) {
            attendanceStatus[record['studentId']] = record['status'];
          }
        });

        _showInfoSnackbar('Loaded existing attendance');
      }
    } catch (e) {
      print('Error loading existing attendance: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      if (selectedSubject != null) {
        await _loadExistingAttendance();
      }
    }
  }

  void _toggleAttendance(String studentId, String status) {
    setState(() {
      attendanceStatus[studentId] = status;
    });
  }

  void _markAllPresent() {
    setState(() {
      for (var student in students) {
        attendanceStatus[student.id] = 'present';
      }
    });
  }

  void _markAllAbsent() {
    setState(() {
      for (var student in students) {
        attendanceStatus[student.id] = 'absent';
      }
    });
  }

  Future<void> _saveAttendance() async {
    if (selectedSubject == null) {
      _showErrorSnackbar('Please select a subject');
      return;
    }

    setState(() => isSaving = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      
      final attendanceList = students.map((student) {
        return {
          'studentId': student.id,
          'name': student.name,
          'rollNumber': student.rollNumber,
          'status': attendanceStatus[student.id] ?? 'absent',
        };
      }).toList();

      final result = await ApiService.markAttendance(
        token: widget.user.token!,
        classId: widget.assignedClass.classId,
        date: dateStr,
        subject: selectedSubject!,
        period: selectedPeriod,
        attendance: attendanceList,
        markedBy: widget.user.id,
        staffName: widget.user.name,
      );

      if (result['success']) {
        _showSuccessSnackbar('Attendance marked successfully');
        Navigator.pop(context, true);
      } else {
        _showErrorSnackbar(result['message'] ?? 'Failed to mark attendance');
      }
    } catch (e) {
      print('Error saving attendance: $e');
      _showErrorSnackbar('Error saving attendance');
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int get presentCount => 
      attendanceStatus.values.where((status) => status == 'present').length;
  
  int get absentCount => 
      attendanceStatus.values.where((status) => status == 'absent').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Attendance - ${widget.assignedClass.fullName}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Card
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Date Selector
                        InkWell(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.deepPurple),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.deepPurple),
                                    const SizedBox(width: 12),
                                    Text(
                                      DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),

                        // Subject Selector
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.book, color: Colors.blue),
                              const SizedBox(width: 12),
                              const Text(
                                'Subject:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedSubject,
                                    isExpanded: true,
                                    items: subjects.map((subject) {
                                      return DropdownMenuItem(
                                        value: subject,
                                        child: Text(subject),
                                      );
                                    }).toList(),
                                    onChanged: (value) async {
                                      setState(() {
                                        selectedSubject = value;
                                      });
                                      await _loadExistingAttendance();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Period Selector (Optional)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule, color: Colors.orange),
                              const SizedBox(width: 12),
                              const Text(
                                'Period:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    value: selectedPeriod,
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Not specified'),
                                      ),
                                      ...periods.map((period) {
                                        return DropdownMenuItem(
                                          value: period,
                                          child: Text('Period $period'),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (value) async {
                                      setState(() {
                                        selectedPeriod = value;
                                      });
                                      await _loadExistingAttendance();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Statistics
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total',
                                students.length.toString(),
                                Colors.blue,
                                Icons.people,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Present',
                                presentCount.toString(),
                                Colors.green,
                                Icons.check_circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Absent',
                                absentCount.toString(),
                                Colors.red,
                                Icons.cancel,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _markAllPresent,
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          label: const Text('Mark All Present'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _markAllAbsent,
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Mark All Absent'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Students List
                Expanded(
                  child: students.isEmpty
                      ? const Center(child: Text('No students found'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final status = attendanceStatus[student.id] ?? 'absent';
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: status == 'present'
                                      ? Colors.green
                                      : Colors.red,
                                  child: Text(
                                    student.rollNumber.isNotEmpty
                                        ? student.rollNumber
                                        : (index + 1).toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  student.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('Roll No: ${student.rollNumber}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _toggleAttendance(student.id, 'present'),
                                      icon: Icon(
                                        status == 'present'
                                            ? Icons.check_circle
                                            : Icons.check_circle_outline,
                                        color: Colors.green,
                                        size: 32,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _toggleAttendance(student.id, 'absent'),
                                      icon: Icon(
                                        status == 'absent'
                                            ? Icons.cancel
                                            : Icons.cancel_outlined,
                                        color: Colors.red,
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Save Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'SAVE ATTENDANCE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}