import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_model.dart';
import '../services/api_service.dart';
import '../core/cache/cache_manager.dart';
import '../core/constants/app_constants.dart';
import 'auth_provider.dart';

// Classes State
class ClassesState {
  final List<AssignedClass> classes;
  final Map<String, List<Student>> classStudents;
  final bool isLoading;
  final String? error;

  ClassesState({
    this.classes = const [],
    this.classStudents = const {},
    this.isLoading = false,
    this.error,
  });

  ClassesState copyWith({
    List<AssignedClass>? classes,
    Map<String, List<Student>>? classStudents,
    bool? isLoading,
    String? error,
  }) {
    return ClassesState(
      classes: classes ?? this.classes,
      classStudents: classStudents ?? this.classStudents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Classes Notifier
class ClassesNotifier extends StateNotifier<ClassesState> {
  ClassesNotifier(this.ref) : super(ClassesState());

  final Ref ref;
  final _cacheManager = CacheManager();

  Future<void> loadStaffClasses(String staffId, {bool forceRefresh = false}) async {
    final user = ref.read(authProvider).user;
    if (user?.token == null) return;

    // Check cache
    if (!forceRefresh) {
      final cachedClasses = _cacheManager.getListFromCache(
        CacheKeys.staffClassesKey(staffId),
        (json) => AssignedClass.fromJson(json),
      );

      if (cachedClasses != null) {
        state = state.copyWith(classes: cachedClasses, isLoading: false);
        return;
      }
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await ApiService.getStaffAssignedClasses(
        token: user!.token!,
        staffId: staffId,
      );

      if (result['success']) {
        final data = result['data'];
        final List<dynamic> classesData = data['assignedClasses'] ?? [];
        final classes = classesData.map((c) => AssignedClass.fromJson(c)).toList();

        // Cache
        await _cacheManager.saveToCache(
          key: CacheKeys.staffClassesKey(staffId),
          data: classesData,
        );

        state = state.copyWith(classes: classes, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadClassStudents(String classId, {bool forceRefresh = false}) async {
    final user = ref.read(authProvider).user;
    if (user?.token == null) return;

    // Check cache
    if (!forceRefresh) {
      final cacheKey = CacheKeys.classStudentsKey(classId);
      final cachedStudents = _cacheManager.getListFromCache(
        cacheKey,
        (json) => Student.fromJson(json),
      );

      if (cachedStudents != null) {
        final updatedMap = Map<String, List<Student>>.from(state.classStudents);
        updatedMap[classId] = cachedStudents;
        state = state.copyWith(classStudents: updatedMap);
        return;
      }
    }

    try {
      final result = await ApiService.getMyClassStudents(
        token: user!.token!,
        classId: classId,
      );

      if (result['success']) {
        final data = result['data'];
        final List<dynamic> studentsData = data['students'] ?? [];
        final students = studentsData.map((s) => Student.fromJson(s)).toList();

        // Cache
        final cacheKey = CacheKeys.classStudentsKey(classId);
        await _cacheManager.saveToCache(
          key: cacheKey,
          data: studentsData,
        );

        final updatedMap = Map<String, List<Student>>.from(state.classStudents);
        updatedMap[classId] = students;
        state = state.copyWith(classStudents: updatedMap);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  List<Student>? getStudentsForClass(String classId) {
    return state.classStudents[classId];
  }
}

// Provider
final classesProvider = StateNotifierProvider<ClassesNotifier, ClassesState>((ref) {
  return ClassesNotifier(ref);
});