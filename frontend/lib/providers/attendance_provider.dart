import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_model.dart';
import '../services/api_service.dart';
import '../core/cache/cache_manager.dart';
import '../core/constants/app_constants.dart';
import 'auth_provider.dart';

// Attendance State
class AttendanceState {
  final StudentAttendanceData? data;
  final bool isLoading;
  final String? error;

  AttendanceState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  AttendanceState copyWith({
    StudentAttendanceData? data,
    bool? isLoading,
    String? error,
  }) {
    return AttendanceState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Attendance Notifier
class AttendanceNotifier extends StateNotifier<AttendanceState> {
  AttendanceNotifier(this.ref) : super(AttendanceState());

  final Ref ref;
  final _cacheManager = CacheManager();

  Future<void> loadStudentAttendance({
    required String studentId,
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh) {
      final cacheKey = CacheKeys.attendanceKey(studentId);
      final cachedData = _cacheManager.getFromCache(
        cacheKey,
        (json) => StudentAttendanceData.fromJson(json),
      );

      if (cachedData != null) {
        state = state.copyWith(data: cachedData, isLoading: false);
        return;
      }
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = ref.read(authProvider).user;
      if (user?.token == null) {
        throw Exception('No authentication token');
      }

      final result = await ApiService.getStudentAttendance(
        token: user!.token!,
        studentId: studentId,
        limit: 100,
      );

      if (result['success'] && result['data'] != null) {
        final data = StudentAttendanceData.fromJson(result['data']);
        
        // Cache the result
        final cacheKey = CacheKeys.attendanceKey(studentId);
        await _cacheManager.saveToCache(
          key: cacheKey,
          data: result['data'],
          duration: AppConstants.cacheDuration,
        );

        state = state.copyWith(data: data, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Failed to load attendance',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh(String studentId) async {
    await loadStudentAttendance(studentId: studentId, forceRefresh: true);
  }
}

// Provider
final attendanceProvider = StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier(ref);
});