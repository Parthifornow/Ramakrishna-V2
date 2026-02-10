import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageManager {
  static final SecureStorageManager _instance = SecureStorageManager._internal();
  factory SecureStorageManager() => _instance;
  SecureStorageManager._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Token Management
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // User ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'user_id', value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  // Session
  Future<void> saveSessionData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> getSessionData(String key) async {
    return await _storage.read(key: key);
  }

  // Clear all
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}