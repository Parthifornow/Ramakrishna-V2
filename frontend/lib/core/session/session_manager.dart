import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/secure_storage.dart';
import '../../models/user_model.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final _secureStorage = SecureStorageManager();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.getToken();
    final userId = await _secureStorage.getUserId();
    return token != null && userId != null;
  }

  // Save session
  Future<void> saveSession({
    required String token,
    required String userId,
    required String userType,
  }) async {
    await _secureStorage.saveToken(token);
    await _secureStorage.saveUserId(userId);
    await _prefs?.setString('user_type', userType);
    await _prefs?.setInt('session_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  // Get session
  Future<Map<String, String?>> getSession() async {
    return {
      'token': await _secureStorage.getToken(),
      'userId': await _secureStorage.getUserId(),
      'userType': _prefs?.getString('user_type'),
    };
  }

  // Check session validity
  Future<bool> isSessionValid() async {
    final timestamp = _prefs?.getInt('session_timestamp');
    if (timestamp == null) return false;

    final sessionDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = DateTime.now().difference(sessionDate);
    
    return difference.inDays < 7; // 7 days validity
  }

  // Clear session
  Future<void> clearSession() async {
    await _secureStorage.clearAll();
    await _prefs?.clear();
  }

  // Refresh session
  Future<void> refreshSession() async {
    await _prefs?.setInt('session_timestamp', DateTime.now().millisecondsSinceEpoch);
  }
}