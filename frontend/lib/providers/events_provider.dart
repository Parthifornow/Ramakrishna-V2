import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import '../core/cache/cache_manager.dart';
import '../core/constants/app_constants.dart';
import 'auth_provider.dart';

// Events State
class EventsState {
  final List<Event> events;
  final bool isLoading;
  final String? error;

  EventsState({
    this.events = const [],
    this.isLoading = false,
    this.error,
  });

  EventsState copyWith({
    List<Event>? events,
    bool? isLoading,
    String? error,
  }) {
    return EventsState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Events Notifier
class EventsNotifier extends StateNotifier<EventsState> {
  EventsNotifier(this.ref) : super(EventsState());

  final Ref ref;
  final _cacheManager = CacheManager();

  Future<void> loadEvents({
    bool forceRefresh = false,
    String filter = 'upcoming',
  }) async {
    final user = ref.read(authProvider).user;
    if (user?.token == null) return;

    // Check cache first
    if (!forceRefresh) {
      final cacheKey = CacheKeys.eventsKey(user!.userType);
      final cachedEvents = _cacheManager.getListFromCache(
        cacheKey,
        (json) => Event.fromJson(json),
      );

      if (cachedEvents != null) {
        state = state.copyWith(events: cachedEvents, isLoading: false);
        return;
      }
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      Map<String, dynamic> result;

      if (user!.userType == 'student') {
        result = await ApiService.getStudentEvents(
          token: user.token!,
          limit: 100,
        );
      } else {
        if (filter == 'my_events') {
          result = await ApiService.getMyEvents(
            token: user.token!,
            limit: 50,
          );
        } else if (filter == 'upcoming') {
          result = await ApiService.getUpcomingEvents(
            token: user.token!,
            limit: 50,
          );
        } else {
          result = await ApiService.getStaffEvents(
            token: user.token!,
            limit: 50,
          );
        }
      }

      if (result['success']) {
        final List<dynamic> eventsData = result['data']['events'] ?? [];
        final events = eventsData.map((e) => Event.fromJson(e)).toList();

        // Cache the result
        final cacheKey = CacheKeys.eventsKey(user.userType);
        await _cacheManager.saveToCache(
          key: cacheKey,
          data: eventsData,
          duration: const Duration(minutes: 30),
        );

        state = state.copyWith(events: events, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Failed to load events',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh({String filter = 'upcoming'}) async {
    await loadEvents(forceRefresh: true, filter: filter);
  }

  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    final user = ref.read(authProvider).user;
    if (user?.token == null) return false;

    try {
      final result = await ApiService.createEvent(
        token: user!.token!,
        title: eventData['title'],
        description: eventData['description'],
        eventDate: eventData['eventDate'],
        eventTime: eventData['eventTime'],
        location: eventData['location'],
        category: eventData['category'],
        targetAudience: eventData['targetAudience'],
        targetClassIds: eventData['targetClassIds'],
        priority: eventData['priority'],
      );

      if (result['success']) {
        // Invalidate cache
        final cacheKey = CacheKeys.eventsKey(user.userType);
        await _cacheManager.clearCache(cacheKey);
        
        // Reload events
        await loadEvents(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    final user = ref.read(authProvider).user;
    if (user?.token == null) return false;

    try {
      final result = await ApiService.deleteEvent(
        token: user!.token!,
        eventId: eventId,
      );

      if (result['success']) {
        // Remove from state
        state = state.copyWith(
          events: state.events.where((e) => e.id != eventId).toList(),
        );
        
        // Invalidate cache
        final cacheKey = CacheKeys.eventsKey(user.userType);
        await _cacheManager.clearCache(cacheKey);
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

// Provider
final eventsProvider = StateNotifierProvider<EventsNotifier, EventsState>((ref) {
  return EventsNotifier(ref);
});