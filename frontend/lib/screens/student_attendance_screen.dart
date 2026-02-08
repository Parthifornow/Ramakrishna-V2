import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../services/api_service.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final User user;

  const StudentAttendanceScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen>
    with SingleTickerProviderStateMixin {
  StudentAttendanceData? attendanceData;
  bool isLoading = true;
  late TabController _tabController;
  
  final List<Color> subjectColors = [
    const Color(0xFF1E88E5),
    const Color(0xFFFB8C00),
    const Color(0xFF43A047),
    const Color(0xFF8E24AA),
    const Color(0xFFE53935),
    const Color(0xFF00ACC1),
    const Color(0xFF7CB342),
    const Color(0xFFD81B60),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAttendance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendance() async {
    setState(() => isLoading = true);

    try {
      final result = await ApiService.getStudentAttendance(
        token: widget.user.token!,
        studentId: widget.user.id,
        limit: 100,
      );

      if (result['success'] && result['data'] != null) {
        setState(() {
          attendanceData = StudentAttendanceData.fromJson(result['data']);
        });
      } else {
        _showSnackbar(result['message'] ?? 'Failed to load attendance', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Error loading attendance data', Colors.red);
    } finally {
      setState(() => isLoading = false);
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

  Color _getPercentageColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 60) return const Color(0xFFFB8C00);
    return Colors.red;
  }

  Color _getSubjectColor(int index) {
    return subjectColors[index % subjectColors.length];
  }

  DateTime? _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Records'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
            )
          : attendanceData == null
              ? const Center(child: Text('No attendance data available'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildRecordsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAttendance,
      color: const Color(0xFF1E88E5),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          attendanceData!.studentName.isNotEmpty
                              ? attendanceData!.studentName[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Color(0xFF1E88E5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attendanceData!.studentName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Class ${attendanceData!.className}-${attendanceData!.section} • Roll: ${attendanceData!.rollNumber}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeaderStatCard(
                          'Total',
                          attendanceData!.overallStatistics.totalDays.toString(),
                          Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHeaderStatCard(
                          'Present',
                          attendanceData!.overallStatistics.presentDays.toString(),
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHeaderStatCard(
                          'Absent',
                          attendanceData!.overallStatistics.absentDays.toString(),
                          Icons.cancel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Overall Percentage Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getPercentageColor(attendanceData!.overallStatistics.attendancePercentage),
                    _getPercentageColor(attendanceData!.overallStatistics.attendancePercentage).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Overall Attendance',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${attendanceData!.overallStatistics.attendancePercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Subject-Wise Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Subject Wise Attendance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Subject-Wise List
            if (attendanceData!.subjectWise.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No subject-wise data available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: attendanceData!.subjectWise.length,
                itemBuilder: (context, index) {
                  final subject = attendanceData!.subjectWise[index];
                  final color = _getSubjectColor(index);
                  
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
                    child: InkWell(
                      onTap: () => _showSubjectDetails(subject, color),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    subject.subject,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${subject.attendancePercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _getPercentageColor(subject.attendancePercentage),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: subject.attendancePercentage / 100,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${subject.presentDays}/${subject.totalDays} classes attended',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsTab() {
    if (attendanceData!.allRecords.isEmpty) {
      return const Center(
        child: Text(
          'No attendance records yet',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAttendance,
      color: const Color(0xFF1E88E5),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: attendanceData!.allRecords.length,
        itemBuilder: (context, index) {
          final record = attendanceData!.allRecords[index];
          return _buildAttendanceRecordCard(record);
        },
      ),
    );
  }

  Widget _buildHeaderStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecordCard(AllAttendanceRecord record) {
    final isPresent = record.status == 'present';
    final date = _parseDate(record.date);
    
    String displayDate;
    String dayOfWeek = '';
    if (date != null) {
      displayDate = DateFormat('d MMM').format(date);
      dayOfWeek = DateFormat('EEE').format(date);
    } else {
      displayDate = record.date;
    }

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date Circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isPresent ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date != null ? date.day.toString() : '--',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (dayOfWeek.isNotEmpty)
                    Text(
                      dayOfWeek,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.subject,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayDate,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (record.period != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Period ${record.period}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPresent ? Colors.green : Colors.red,
                ),
              ),
              child: Text(
                isPresent ? 'P' : 'A',
                style: TextStyle(
                  color: isPresent ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubjectDetails(SubjectAttendanceStats subject, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.subject,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${subject.presentDays}/${subject.totalDays} classes attended',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${subject.attendancePercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Records List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: subject.records.length,
                  itemBuilder: (context, index) {
                    final record = subject.records[index];
                    final isPresent = record.status == 'present';
                    final date = _parseDate(record.date);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isPresent ? Icons.check_circle : Icons.cancel,
                          color: isPresent ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          date != null
                              ? DateFormat('EEE, MMM d, yyyy').format(date)
                              : record.date,
                        ),
                        subtitle: record.period != null
                            ? Text('Period ${record.period}')
                            : null,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPresent ? 'P' : 'A',
                            style: TextStyle(
                              color: isPresent ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}