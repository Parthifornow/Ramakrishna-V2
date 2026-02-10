import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../core/session/session_manager.dart';
import '../core/cache/cache_manager.dart';

// Auth State
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  final _sessionManager = SessionManager();
  final _cacheManager = CacheManager();

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      print('🔍 Checking auth status...');
      
      final isLoggedIn = await _sessionManager.isLoggedIn();
      final isValid = await _sessionManager.isSessionValid();
      
      print('📱 Session check: isLoggedIn=$isLoggedIn, isValid=$isValid');

      if (isLoggedIn && isValid) {
        final session = await _sessionManager.getSession();
        final token = session['token'];
        
        print('🔑 Token exists: ${token != null}');

        if (token != null) {
          // Try to get user from cache first
          final cachedUser = _cacheManager.getFromCache(
            'current_user',
            (json) => User.fromJson(json),
          );

          if (cachedUser != null) {
            print('✅ User loaded from cache: ${cachedUser.name}');
            state = state.copyWith(
              user: cachedUser.copyWith(token: token),
              isAuthenticated: true,
              isLoading: false,
            );
            return;
          }

          // If not in cache, fetch from API
          print('📡 Fetching user from API...');
          final result = await ApiService.getProfile(token: token);

          if (result['success']) {
            final user = User.fromJson(result['user']).copyWith(token: token);
            
            print('✅ User fetched from API: ${user.name}');
            
            state = state.copyWith(
              user: user,
              isAuthenticated: true,
              isLoading: false,
            );

            // Cache the user
            await _cacheManager.saveToCache(
              key: 'current_user',
              data: user.toJson(),
            );
          } else {
            print('❌ Failed to fetch profile, logging out');
            await logout();
          }
        } else {
          print('❌ No token found');
          state = state.copyWith(isLoading: false, isAuthenticated: false);
        }
      } else {
        print('❌ Session invalid or not logged in');
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    } catch (e) {
      print('❌ Auth check error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isAuthenticated: false,
      );
    }
  }

  Future<bool> login(String phoneNumber, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔐 Attempting login for: $phoneNumber');
      
      final result = await ApiService.login(
        phoneNumber: phoneNumber,
        password: password,
      );

      if (result['success']) {
        final userData = result['data']['user'];
        final token = result['data']['token'];
        final user = User.fromJson(userData).copyWith(token: token);

        print('✅ Login successful: ${user.name}');

        // Save session
        await _sessionManager.saveSession(
          token: token,
          userId: user.id,
          userType: user.userType,
        );

        // Cache user
        await _cacheManager.saveToCache(
          key: 'current_user',
          data: user.toJson(),
        );

        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );

        return true;
      } else {
        print('❌ Login failed: ${result['message']}');
        state = state.copyWith(
          isLoading: false,
          error: result['message'] ?? 'Login failed',
        );
        return false;
      }
    } catch (e) {
      print('❌ Login error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    print('🚪 Logging out...');
    await _sessionManager.clearSession();
    await _cacheManager.clearAllCache();
    state = AuthState();
    print('✅ Logged out successfully');
  }

  Future<void> refreshSession() async {
    await _sessionManager.refreshSession();
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});