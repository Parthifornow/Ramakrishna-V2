import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Replace with your backend URL
  static const String baseUrl = 'http://10.187.61.124:3000/api';

  // Pre-register - Save user data before phone verification
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
    try {
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

      final response = await http.post(
        Uri.parse('$baseUrl/auth/pre-register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Data saved successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Pre-registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Complete registration after phone verification
  static Future<Map<String, dynamic>> completeRegistration({
    required String phoneNumber,
    required String firebaseUid,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/complete-registration'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'firebaseUid': firebaseUid,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? 'Registration completed',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration completion failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Login endpoint
  static Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Reset Password endpoint
  static Future<Map<String, dynamic>> resetPassword({
    required String phoneNumber,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'newPassword': newPassword,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Password reset failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get user profile (protected)
  static Future<Map<String, dynamic>> getProfile({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // ATTENDANCE API METHODS
  
  // Mark attendance for a class
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
    try {
      print('📝 Marking attendance for class $classId on $date');
      
      final Map<String, dynamic> body = {
        'classId': classId,
        'date': date,
        'attendance': attendance,
        'markedBy': markedBy,
      };
      
      if (subject != null) body['subject'] = subject;
      if (period != null) body['period'] = period;
      if (staffName != null) body['staffName'] = staffName;
      
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/mark'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);
      print('📦 Mark attendance response: $responseData');

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to mark attendance',
        };
      }
    } catch (e) {
      print('❌ Mark attendance error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get attendance for a specific class and date
  static Future<Map<String, dynamic>> getClassAttendance({
    required String token,
    required String classId,
    required String date,
    String? subject,
    String? period,
  }) async {
    try {
      print('📖 Fetching attendance for class $classId on $date');
      
      var url = '$baseUrl/attendance/class/$classId/date/$date';
      final queryParams = <String, String>{};
      
      if (subject != null) queryParams['subject'] = subject;
      if (period != null) queryParams['period'] = period;
      
      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      print('📦 Get attendance response: $responseData');

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch attendance',
        };
      }
    } catch (e) {
      print('❌ Get attendance error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get attendance history for a class
  static Future<Map<String, dynamic>> getClassAttendanceHistory({
    required String token,
    required String classId,
    int limit = 30,
    String? subject,
  }) async {
    try {
      print('📚 Fetching attendance history for class $classId');
      
      var url = '$baseUrl/attendance/class/$classId/history?limit=$limit';
      if (subject != null) {
        url += '&subject=$subject';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch history',
        };
      }
    } catch (e) {
      print('❌ Get history error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get student's attendance record
  static Future<Map<String, dynamic>> getStudentAttendance({
    required String token,
    required String studentId,
    int limit = 100,
  }) async {
    try {
      print('👨‍🎓 Fetching attendance for student $studentId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/student/$studentId?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch attendance',
        };
      }
    } catch (e) {
      print('❌ Get student attendance error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get attendance summary for a class
  static Future<Map<String, dynamic>> getClassAttendanceSummary({
    required String token,
    required String classId,
  }) async {
    try {
      print('📊 Fetching attendance summary for class $classId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/class/$classId/summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch summary',
        };
      }
    } catch (e) {
      print('❌ Get summary error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get staff attendance summary
  static Future<Map<String, dynamic>> getStaffAttendanceSummary({
    required String token,
  }) async {
    try {
      print('📊 Fetching staff attendance summary');
      
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/staff/summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch summary',
        };
      }
    } catch (e) {
      print('❌ Get summary error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get all classes
  static Future<Map<String, dynamic>> getAllClasses({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/class/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch classes',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get students in a class
  static Future<Map<String, dynamic>> getClassStudents({
    required String token,
    required String classId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/class/$classId/students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch students',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get my students (for staff)
  static Future<Map<String, dynamic>> getMyStudents({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/staff/my-students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch students',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get staff's assigned classes
  static Future<Map<String, dynamic>> getStaffAssignedClasses({
    required String token,
    required String staffId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/staff/assigned-classes/$staffId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch assigned classes',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get students from a specific class (for staff)
  static Future<Map<String, dynamic>> getMyClassStudents({
    required String token,
    required String classId,
  }) async {
    try {
      print('📞 API: Fetching students for class $classId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/staff/my-class/$classId/students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      print('📦 API Response: $responseData');

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch class students',
        };
      }
    } catch (e) {
      print('❌ API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get all staff
  static Future<Map<String, dynamic>> getAllStaff({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/staff/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch staff',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Assign staff to classes
  static Future<Map<String, dynamic>> assignStaffToClasses({
    required String token,
    required String staffId,
    required List<String> classIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/staff/assign-classes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'staffId': staffId,
          'classIds': classIds,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to assign staff',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Add a class to staff
  static Future<Map<String, dynamic>> addClassToStaff({
    required String token,
    required String staffId,
    required String classId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/staff/add-class'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'staffId': staffId,
          'classId': classId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to add class',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Remove a class from staff
  static Future<Map<String, dynamic>> removeClassFromStaff({
    required String token,
    required String staffId,
    required String classId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/staff/remove-class'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'staffId': staffId,
          'classId': classId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to remove class',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // EVENTS API METHODS
  
  // Create event (Staff only)
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
    try {
      print('📅 Creating event: $title');
      
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
      
      final response = await http.post(
        Uri.parse('$baseUrl/events/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create event',
        };
      }
    } catch (e) {
      print('❌ Create event error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get events for students
  static Future<Map<String, dynamic>> getStudentEvents({
    required String token,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/student/all?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch events',
        };
      }
    } catch (e) {
      print('❌ Get student events error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get events for staff
  static Future<Map<String, dynamic>> getStaffEvents({
    required String token,
    int limit = 50,
    bool includeInactive = false,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/staff/all?limit=$limit&includeInactive=$includeInactive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch events',
        };
      }
    } catch (e) {
      print('❌ Get staff events error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get my created events
  static Future<Map<String, dynamic>> getMyEvents({
    required String token,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/my-events?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch events',
        };
      }
    } catch (e) {
      print('❌ Get my events error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get upcoming events
  static Future<Map<String, dynamic>> getUpcomingEvents({
    required String token,
    int limit = 5,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/upcoming?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch events',
        };
      }
    } catch (e) {
      print('❌ Get upcoming events error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update event
  static Future<Map<String, dynamic>> updateEvent({
    required String token,
    required String eventId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update event',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Delete event
  static Future<Map<String, dynamic>> deleteEvent({
    required String token,
    required String eventId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete event',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}