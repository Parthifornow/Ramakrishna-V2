import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';
import '../services/api_service.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  final User user;
  final AssignedClass assignedClass;

  const MarkAttendanceScreen({
    Key? key,
    required this.user,
    required this.assignedClass,
  }) : super(key: key);

  @override
  ConsumerState<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
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
    // Use addPostFrameCallback to load data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudents();
    });
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
    if (!mounted) return;
    
    setState(() => isLoading = true);

    try {
      print('🔍 Loading students for class: ${widget.assignedClass.classId}');
      
      // Load directly from API instead of through provider
      final result = await ApiService.getMyClassStudents(
        token: widget.user.token!,
        classId: widget.assignedClass.classId,
      );

      if (!mounted) return;

      if (result['success'] && result['data'] != null) {
        final data = result['data'];
        final List<dynamic> studentsData = data['students'] ?? [];
        final loadedStudents = studentsData.map((s) => Student.fromJson(s)).toList();

        print('📚 Loaded students count: ${loadedStudents.length}');

        if (loadedStudents.isNotEmpty) {
          setState(() {
            students = loadedStudents;
            
            // Initialize attendance status for all students
            for (var student in students) {
              attendanceStatus[student.id] = 'absent';
            }
          });

          // Load existing attendance if subject is selected
          if (selectedSubject != null) {
            await _loadExistingAttendance();
          }
        } else {
          print('⚠️ No students found for class ${widget.assignedClass.classId}');
          _showSnackbar('No students found in this class', Colors.orange);
        }
      } else {
        print('❌ Failed to load students: ${result['message']}');
        _showSnackbar('Failed to load students: ${result['message'] ?? 'Unknown error'}', Colors.red);
      }
    } catch (e) {
      print('❌ Error loading students: $e');
      if (mounted) {
        _showSnackbar('Failed to load students: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
        
        if (attendanceList.isNotEmpty && mounted) {
          setState(() {
            for (var record in attendanceList) {
              attendanceStatus[record['studentId']] = record['status'];
            }
          });

          _showSnackbar('Loaded existing attendance', const Color(0xFF00B4D8));
        }
      }
    } catch (e) {
      // Silent fail for existing attendance
      print('ℹ️ No existing attendance found or error: $e');
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
              primary: Color(0xFF00B4D8),
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

    if (students.isEmpty) {
      _showSnackbar('No students to mark attendance for', Colors.red);
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

      print('📝 Saving attendance for ${students.length} students');

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
      print('❌ Error saving attendance: $e');
      _showSnackbar('Error saving attendance: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Mark Attendance • ${widget.assignedClass.fullName}'),
        backgroundColor: const Color(0xFF00B4D8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00B4D8)),
            )
          : Column(
              children: [
                // Date, Subject, Period Selection Card
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      // Date Selector
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B4D8).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF00B4D8).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Color(0xFF00B4D8), size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.arrow_drop_down, color: Color(0xFF00B4D8)),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 14),

                      // Subject and Period Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B4D8).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF00B4D8).withOpacity(0.3),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedSubject,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00B4D8)),
                                  items: subjects.map((subject) {
                                    return DropdownMenuItem(
                                      value: subject,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.book, size: 18, color: Color(0xFF00B4D8)),
                                          const SizedBox(width: 8),
                                          Text(subject, style: const TextStyle(fontSize: 14)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0096C7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF0096C7).withOpacity(0.3),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: selectedPeriod,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0096C7)),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Row(
                                        children: [
                                          Icon(Icons.schedule, size: 18, color: Color(0xFF0096C7)),
                                          SizedBox(width: 8),
                                          Text('Any', style: TextStyle(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    ...periods.map((period) {
                                      return DropdownMenuItem(
                                        value: period,
                                        child: Row(
                                          children: [
                                            const Icon(Icons.schedule, size: 18, color: Color(0xFF0096C7)),
                                            const SizedBox(width: 8),
                                            Text('Period $period', style: const TextStyle(fontSize: 14)),
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
                      
                      const SizedBox(height: 20),
                      
                      // Statistics
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total',
                              students.length.toString(),
                              const Color(0xFF00B4D8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: students.isEmpty ? null : _markAllPresent,
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('All Present'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: students.isEmpty ? null : _markAllAbsent,
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('All Absent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Students List
                Expanded(
                  child: students.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No students found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Class ${widget.assignedClass.fullName}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadStudents,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00B4D8),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                border: Border.all(
                                  color: isPresent 
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: isPresent 
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  child: Text(
                                    student.rollNumber.isNotEmpty
                                        ? student.rollNumber
                                        : (index + 1).toString(),
                                    style: TextStyle(
                                      color: isPresent ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  'Roll No: ${student.rollNumber.isNotEmpty ? student.rollNumber : "N/A"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => _toggleAttendance(student.id, 'present'),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          isPresent ? Icons.check_circle : Icons.check_circle_outline,
                                          color: Colors.green,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _toggleAttendance(student.id, 'absent'),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          !isPresent ? Icons.cancel : Icons.cancel_outlined,
                                          color: Colors.red,
                                          size: 28,
                                        ),
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                        onPressed: (isSaving || students.isEmpty) ? null : _saveAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B4D8),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
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
                                  fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}