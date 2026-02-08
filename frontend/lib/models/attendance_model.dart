class AttendanceRecord {
  final String studentId;
  final String name;
  final String rollNumber;
  final String status; // 'present', 'absent'

  AttendanceRecord({
    required this.studentId,
    required this.name,
    required this.rollNumber,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      studentId: json['studentId'] ?? '',
      name: json['name'] ?? '',
      rollNumber: json['rollNumber'] ?? '',
      status: json['status'] ?? 'absent',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'name': name,
      'rollNumber': rollNumber,
      'status': status,
    };
  }

  AttendanceRecord copyWith({String? status}) {
    return AttendanceRecord(
      studentId: studentId,
      name: name,
      rollNumber: rollNumber,
      status: status ?? this.status,
    );
  }
}

class SubjectAttendanceStats {
  final String subject;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final double attendancePercentage;
  final List<AttendanceRecordDetail> records;

  SubjectAttendanceStats({
    required this.subject,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.attendancePercentage,
    required this.records,
  });

  factory SubjectAttendanceStats.fromJson(Map<String, dynamic> json) {
    final recordsList = json['records'] as List<dynamic>? ?? [];
    
    return SubjectAttendanceStats(
      subject: json['subject'] ?? '',
      totalDays: json['totalDays'] ?? 0,
      presentDays: json['presentDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      attendancePercentage: (json['attendancePercentage'] ?? 0).toDouble(),
      records: recordsList
          .map((item) => AttendanceRecordDetail.fromJson(item))
          .toList(),
    );
  }
}

class AttendanceRecordDetail {
  final String date;
  final String? period;
  final String status;
  final String? staffName;
  final DateTime? markedAt;

  AttendanceRecordDetail({
    required this.date,
    this.period,
    required this.status,
    this.staffName,
    this.markedAt,
  });

  factory AttendanceRecordDetail.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordDetail(
      date: json['date'] ?? '',
      period: json['period'],
      status: json['status'] ?? '',
      staffName: json['staffName'],
      markedAt: _parseTimestamp(json['markedAt']),
    );
  }
}

class StudentAttendanceData {
  final String studentId;
  final String studentName;
  final String classId;
  final String className;
  final String section;
  final String rollNumber;
  final AttendanceStatistics overallStatistics;
  final List<SubjectAttendanceStats> subjectWise;
  final List<AllAttendanceRecord> allRecords;

  StudentAttendanceData({
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.section,
    required this.rollNumber,
    required this.overallStatistics,
    required this.subjectWise,
    required this.allRecords,
  });

  factory StudentAttendanceData.fromJson(Map<String, dynamic> json) {
    final overallStats = json['overallStatistics'] as Map<String, dynamic>? ?? {};
    final subjectWiseList = json['subjectWise'] as List<dynamic>? ?? [];
    final allRecordsList = json['allRecords'] as List<dynamic>? ?? [];

    return StudentAttendanceData(
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      classId: json['classId'] ?? '',
      className: json['className'] ?? '',
      section: json['section'] ?? '',
      rollNumber: json['rollNumber'] ?? '',
      overallStatistics: AttendanceStatistics.fromJson(overallStats),
      subjectWise: subjectWiseList
          .map((item) => SubjectAttendanceStats.fromJson(item))
          .toList(),
      allRecords: allRecordsList
          .map((item) => AllAttendanceRecord.fromJson(item))
          .toList(),
    );
  }
}

class AllAttendanceRecord {
  final String date;
  final String subject;
  final String? period;
  final String status;
  final String? staffName;
  final DateTime? markedAt;

  AllAttendanceRecord({
    required this.date,
    required this.subject,
    this.period,
    required this.status,
    this.staffName,
    this.markedAt,
  });

  factory AllAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AllAttendanceRecord(
      date: json['date'] ?? '',
      subject: json['subject'] ?? '',
      period: json['period'],
      status: json['status'] ?? '',
      staffName: json['staffName'],
      markedAt: _parseTimestamp(json['markedAt']),
    );
  }
}

class AttendanceStatistics {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final double attendancePercentage;

  AttendanceStatistics({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.attendancePercentage,
  });

  factory AttendanceStatistics.fromJson(Map<String, dynamic> json) {
    return AttendanceStatistics(
      totalDays: json['totalDays'] ?? 0,
      presentDays: json['presentDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      attendancePercentage: (json['attendancePercentage'] ?? 0).toDouble(),
    );
  }
}

// Helper function to parse Firestore Timestamp objects
DateTime? _parseTimestamp(dynamic timestamp) {
  if (timestamp == null) return null;
  
  try {
    if (timestamp is Map) {
      final seconds = timestamp['_seconds'];
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }
    
    if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    
    if (timestamp is DateTime) {
      return timestamp;
    }
  } catch (e) {
    print('⚠️ Error parsing timestamp: $e');
  }
  
  return null;
}