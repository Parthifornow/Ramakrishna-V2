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
        // FIXED: Return backend response directly
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
        // Return the response directly without wrapping
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
        // FIXED: Return backend response directly
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
}