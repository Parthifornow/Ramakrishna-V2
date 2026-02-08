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
          
          for (var student in students) {
            attendanceStatus[student.id] = 'absent';
          }
        });

        if (selectedSubject != null) {
          await _loadExistingAttendance();
        }
      }
    } catch (e) {
      _showSnackbar('Failed to load students', Colors.red);
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

        _showSnackbar('Loaded existing attendance', const Color(0xFF1E88E5));
      }
    } catch (e) {
      // Silent fail for existing attendance
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6750A4),
            ),
          ),
          child: child!,
        );
      },
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
      _showSnackbar('Please select a subject', Colors.red);
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
        _showSnackbar('Attendance marked successfully', Colors.green);
        Navigator.pop(context, true);
      } else {
        _showSnackbar(result['message'] ?? 'Failed to mark attendance', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Error saving attendance', Colors.red);
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Mark Attendance • ${widget.assignedClass.fullName}'),
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6750A4)),
            )
          : Column(
              children: [
                // Date, Subject, Period Selection Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Date Selector
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6750A4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF6750A4).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Color(0xFF6750A4)),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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

                      // Subject and Period Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E88E5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF1E88E5).withOpacity(0.3),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedSubject,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  items: subjects.map((subject) {
                                    return DropdownMenuItem(
                                      value: subject,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.book, size: 20, color: Color(0xFF1E88E5)),
                                          const SizedBox(width: 8),
                                          Text(subject),
                                        ],
                                      ),
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFB8C00).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFB8C00).withOpacity(0.3),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: selectedPeriod,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Row(
                                        children: [
                                          Icon(Icons.schedule, size: 20, color: Color(0xFFFB8C00)),
                                          SizedBox(width: 8),
                                          Text('Any'),
                                        ],
                                      ),
                                    ),
                                    ...periods.map((period) {
                                      return DropdownMenuItem(
                                        value: period,
                                        child: Row(
                                          children: [
                                            const Icon(Icons.schedule, size: 20, color: Color(0xFFFB8C00)),
                                            const SizedBox(width: 8),
                                            Text('Period $period'),
                                          ],
                                        ),
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
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Statistics
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total',
                              students.length.toString(),
                              const Color(0xFF1E88E5),
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

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _markAllPresent,
                          icon: const Icon(Icons.check_circle, size: 20),
                          label: const Text('All Present'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _markAllAbsent,
                          icon: const Icon(Icons.cancel, size: 20),
                          label: const Text('All Absent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                            final isPresent = status == 'present';
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  backgroundColor: isPresent ? Colors.green : Colors.red,
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text('Roll No: ${student.rollNumber}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _toggleAttendance(student.id, 'present'),
                                      icon: Icon(
                                        isPresent ? Icons.check_circle : Icons.check_circle_outline,
                                        color: Colors.green,
                                        size: 32,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _toggleAttendance(student.id, 'absent'),
                                      icon: Icon(
                                        !isPresent ? Icons.cancel : Icons.cancel_outlined,
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
                          backgroundColor: const Color(0xFF6750A4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}