import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../providers/attendance_provider.dart';
import '../widgets/sticky_header_widget.dart';

class StudentAttendanceScreen extends ConsumerStatefulWidget {
  final User user;

  const StudentAttendanceScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  ConsumerState<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends ConsumerState<StudentAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    // Load attendance data
    Future.microtask(() {
      ref.read(attendanceProvider.notifier).loadStudentAttendance(
        studentId: widget.user.id,
      );
    });
  }

  Color _getBarColor(int index) {
    final colors = [
      const Color(0xFF00B4D8),
      const Color(0xFF0096C7),
      const Color(0xFF48CAE4),
      const Color(0xFF90E0EF),
      const Color(0xFF00B4D8).withOpacity(0.7),
    ];
    return colors[index % colors.length];
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
    final attendanceState = ref.watch(attendanceProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky Header
            StickyHeader(
              greeting: 'Attendance',
              name: widget.user.name,
              subtitle: 'Academic Year 2025-2026',
            ),

            // Content
            Expanded(
              child: attendanceState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00B4D8)),
                    )
                  : attendanceState.data == null
                      ? const Center(child: Text('No attendance data available'))
                      : RefreshIndicator(
                          onRefresh: () async {
                            await ref.read(attendanceProvider.notifier).refresh(widget.user.id);
                          },
                          color: const Color(0xFF00B4D8),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),

                                // Overall Stats Cards
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Total Classes',
                                          attendanceState.data!.subjectWise.isNotEmpty
                                              ? attendanceState.data!.subjectWise.first.totalDays.toString()
                                              : '0',
                                          Icons.calendar_month,
                                          const Color(0xFF00B4D8),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatCard(
                                          'Present',
                                          attendanceState.data!.subjectWise.isNotEmpty
                                              ? attendanceState.data!.subjectWise.first.presentDays.toString()
                                              : '0',
                                          Icons.check_circle,
                                          Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Subject-wise Attendance
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    'Subject-wise Attendance',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Subject Cards
                                if (attendanceState.data!.subjectWise.isNotEmpty)
                                  ...attendanceState.data!.subjectWise.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final subject = entry.value;
                                    final percentage = subject.attendancePercentage;
                                    final color = _getBarColor(index);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
                                      padding: const EdgeInsets.all(16),
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
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: color.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '${percentage.toStringAsFixed(1)}%',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: color,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(Icons.check_circle, 
                                                size: 16, 
                                                color: Colors.grey[600]
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${subject.presentDays} present',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Icon(Icons.calendar_today, 
                                                size: 16, 
                                                color: Colors.grey[600]
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${subject.totalDays} total',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: percentage / 100,
                                              minHeight: 8,
                                              backgroundColor: Colors.grey[200],
                                              valueColor: AlwaysStoppedAnimation<Color>(color),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),

                                const SizedBox(height: 24),

                                // Recent Records
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    'Recent Records',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Attendance Records
                                if (attendanceState.data!.allRecords.isNotEmpty)
                                  ...attendanceState.data!.allRecords.take(10).map((record) {
                                    final date = _parseDate(record.date);
                                    final isPresent = record.status == 'present';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8, left: 20, right: 20),
                                      padding: const EdgeInsets.all(14),
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
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: isPresent 
                                                  ? Colors.green.withOpacity(0.1)
                                                  : Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  date != null ? date.day.toString() : '--',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: isPresent ? Colors.green : Colors.red,
                                                  ),
                                                ),
                                                Text(
                                                  date != null 
                                                      ? DateFormat('MMM').format(date).toUpperCase()
                                                      : '--',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: isPresent ? Colors.green : Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  date != null 
                                                      ? DateFormat('EEEE, MMM d, yyyy').format(date)
                                                      : record.date,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      isPresent ? Icons.check_circle : Icons.cancel,
                                                      size: 14,
                                                      color: isPresent ? Colors.green : Colors.red,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      isPresent ? 'Present' : 'Absent',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: isPresent ? Colors.green : Colors.red,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}