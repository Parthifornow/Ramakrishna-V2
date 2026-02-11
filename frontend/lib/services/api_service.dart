import './network_service.dart';

class ApiService {
  static final _network = NetworkService();

  static void init() {
    _network.init();
  }

  // AUTH ENDPOINTS
  
  static Future<Map<String, dynamic>> preRegister({
    required String phoneNumber,
    required String password,
    required String name,
    required String userType,
    String? className,
    String? section,
    String? rollNumber,
    String? designation,
    List<String>? subjects,
  }) async {
    final Map<String, dynamic> body = {
      'phoneNumber': phoneNumber,
      'password': password,
      'name': name,
      'userType': userType,
    };

    if (userType == 'student') {
      body['class'] = className ?? '';
      body['section'] = section ?? '';
      body['rollNumber'] = rollNumber ?? '';
    } else if (userType == 'staff') {
      body['designation'] = designation ?? '';
      if (subjects != null) {
        body['subjects'] = subjects;
      }
    }

    return await _network.post('/auth/pre-register', data: body);
  }

  static Future<Map<String, dynamic>> completeRegistration({
    required String phoneNumber,
    required String firebaseUid,
  }) async {
    return await _network.post(
      '/auth/complete-registration',
      data: {
        'phoneNumber': phoneNumber,
        'firebaseUid': firebaseUid,
      },
    );
  }

  static Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    return await _network.post(
      '/auth/login',
      data: {
        'phoneNumber': phoneNumber,
        'password': password,
      },
      useRetry: false,
    );
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String phoneNumber,
    required String newPassword,
  }) async {
    return await _network.post(
      '/auth/reset-password',
      data: {
        'phoneNumber': phoneNumber,
        'newPassword': newPassword,
      },
    );
  }

  static Future<Map<String, dynamic>> getProfile({
    required String token,
  }) async {
    return await _network.get('/auth/profile', token: token);
  }

  // ATTENDANCE ENDPOINTS
  
  static Future<Map<String, dynamic>> markAttendance({
    required String token,
    required String classId,
    required String date,
    required List<Map<String, dynamic>> attendance,
    required String markedBy,
    String? subject,
    String? period,
    String? staffName,
  }) async {
    final Map<String, dynamic> body = {
      'classId': classId,
      'date': date,
      'attendance': attendance,
      'markedBy': markedBy,
    };

    if (subject != null) body['subject'] = subject;
    if (period != null) body['period'] = period;
    if (staffName != null) body['staffName'] = staffName;

    return await _network.post(
      '/attendance/mark',
      data: body,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> getClassAttendance({
    required String token,
    required String classId,
    required String date,
    String? subject,
    String? period,
  }) async {
    final queryParams = <String, dynamic>{};
    if (subject != null) queryParams['subject'] = subject;
    if (period != null) queryParams['period'] = period;

    return await _network.get(
      '/attendance/class/$classId/date/$date',
      queryParameters: queryParams,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> getClassAttendanceHistory({
    required String token,
    required String classId,
    int limit = 30,
    String? subject,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (subject != null) queryParams['subject'] = subject;

    return await _network.get(
      '/attendance/class/$classId/history',
      queryParameters: queryParams,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> getStudentAttendance({
    required String token,
    required String studentId,
    int limit = 100,
    int? page,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (page != null) queryParams['page'] = page;

    return await _network.get(
      '/attendance/student/$studentId',
      queryParameters: queryParams,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> getClassAttendanceSummary({
    required String token,
    required String classId,
  }) async {
    return await _network.get(
      '/attendance/class/$classId/summary',
      token: token,
    );
  }

  static Future<Map<String, dynamic>> getStaffAttendanceSummary({
    required String token,
  }) async {
    return await _network.get(
      '/attendance/staff/summary',
      token: token,
    );
  }

  // CLASS ENDPOINTS
  
  static Future<Map<String, dynamic>> getAllClasses({
    required String token,
  }) async {
    return await _network.get('/class/all', token: token);
  }

  static Future<Map<String, dynamic>> getClassStudents({
    required String token,
    required String classId,
  }) async {
    return await _network.get('/class/$classId/students', token: token);
  }

  // STAFF ENDPOINTS
  
  static Future<Map<String, dynamic>> getMyStudents({
    required String token,
  }) async {
    return await _network.get('/staff/my-students', token: token);
  }

  static Future<Map<String, dynamic>> getStaffAssignedClasses({
    required String token,
    required String staffId,
  }) async {
    return await _network.get(
      '/staff/assigned-classes/$staffId',
      token: token,
    );
  }

  static Future<Map<String, dynamic>> getMyClassStudents({
    required String token,
    required String classId,
  }) async {
    return await _network.get(
      '/staff/my-class/$classId/students',
      token: token,
    );
  }

  static Future<Map<String, dynamic>> getAllStaff({
    required String token,
  }) async {
    return await _network.get('/staff/all', token: token);
  }

  static Future<Map<String, dynamic>> assignStaffToClasses({
    required String token,
    required String staffId,
    required List<String> classIds,
  }) async {
    return await _network.post(
      '/staff/assign-classes',
      data: {
        'staffId': staffId,
        'classIds': classIds,
      },
      token: token,
    );
  }

  static Future<Map<String, dynamic>> addClassToStaff({
    required String token,
    required String staffId,
    required String classId,
  }) async {
    return await _network.post(
      '/staff/add-class',
      data: {
        'staffId': staffId,
        'classId': classId,
      },
      token: token,
    );
  }

  static Future<Map<String, dynamic>> removeClassFromStaff({
    required String token,
    required String staffId,
    required String classId,
  }) async {
    return await _network.post(
      '/staff/remove-class',
      data: {
        'staffId': staffId,
        'classId': classId,
      },
      token: token,
    );
  }

  // EVENT ENDPOINTS
  
  static Future<Map<String, dynamic>> createEvent({
    required String token,
    required String title,
    required String description,
    required String eventDate,
    String? eventTime,
    String? location,
    required String category,
    required String targetAudience,
    List<String>? targetClassIds,
    required String priority,
    String? imageUrl,
  }) async {
    final Map<String, dynamic> body = {
      'title': title,
      'description': description,
      'eventDate': eventDate,
      'category': category,
      'targetAudience': targetAudience,
      'priority': priority,
    };

    if (eventTime != null) body['eventTime'] = eventTime;
    if (location != null) body['location'] = location;
    if (targetClassIds != null) body['targetClassIds'] = targetClassIds;
    if (imageUrl != null) body['imageUrl'] = imageUrl;

    return await _network.post('/events/create', data: body, token: token);
  }

  static Future<Map<String, dynamic>> getStudentEvents({
    required String token,
    int limit = 50,
  }) async {
    return await _network.get(
      '/events/student/all',
      queryParameters: {'limit': limit},
      token: token,
    );
  }

  static Future<Map<String, dynamic>> getStaffEvents({
    required String token,
    int limit = 50,
    bool includeInactive = false,
  }) async {
    return await _network.get(
      '/events/staff/all',
      queryParameters: {
        'limit': limit,
        'includeInactive': includeInactive,
      },
      token: token,
    );
  }

  static Future<Map<String, dynamic>> getMyEvents({
    required String token,
    int limit = 50,
  }) async {
    return await _network.get(
      '/events/my-events',
      queryParameters: {'limit': limit},
      token: token,
    );
  }

  static Future<Map<String, dynamic>> getUpcomingEvents({
    required String token,
    int limit = 5,
  }) async {
    return await _network.get(
      '/events/upcoming',
      queryParameters: {'limit': limit},
      token: token,
    );
  }

  static Future<Map<String, dynamic>> updateEvent({
    required String token,
    required String eventId,
    required Map<String, dynamic> updateData,
  }) async {
    return await _network.put(
      '/events/$eventId',
      data: updateData,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> deleteEvent({
    required String token,
    required String eventId,
  }) async {
    return await _network.delete('/events/$eventId', token: token);
  }
}