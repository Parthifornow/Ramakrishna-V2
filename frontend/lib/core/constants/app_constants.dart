class AppConstants {

  static const String baseUrl = 'http://192.168.1.7:3000/api'; 
  
  // Cache Keys
  static const String cacheKeyUser = 'cached_user';
  static const String cacheKeyToken = 'auth_token';
  static const String cacheKeyAttendance = 'cached_attendance';
  static const String cacheKeyEvents = 'cached_events';
  static const String cacheKeyClasses = 'cached_classes';
  
  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 1);
  static const Duration sessionDuration = Duration(days: 7);
  
  // Hive Boxes
  static const String userBox = 'user_box';
  static const String attendanceBox = 'attendance_box';
  static const String eventsBox = 'events_box';
  static const String cacheBox = 'cache_box';
}

class CacheKeys {
  static String attendanceKey(String studentId) => 'attendance_$studentId';
  static String eventsKey(String userType) => 'events_$userType';
  static String classStudentsKey(String classId) => 'class_students_$classId';
  static String staffClassesKey(String staffId) => 'staff_classes_$staffId';
}