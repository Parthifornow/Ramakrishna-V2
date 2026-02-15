import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'core/cache/cache_manager.dart';
import 'core/session/session_manager.dart';
import 'services/network_service.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/get_started.dart';
import 'screens/staff_dashboard.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // Initialize all services in parallel
    await Future.wait([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      CacheManager().init(),
      SessionManager().init(),
    ]);

    // These are synchronous, call immediately
    NetworkService().init();
    ApiService.init();

    runApp(const ProviderScope(child: MyApp()));
  } catch (e) {
    FlutterNativeSplash.remove();
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Error: $e')))));
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Reduced delay from 2 seconds to 500ms
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check auth in background
    ref.read(authProvider.notifier).checkAuthStatus();
    
    // Remove splash immediately
    if (mounted) {
      FlutterNativeSplash.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Ramakrishna School',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF00B4D8),
      ),
      home: authState.isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF00B4D8))))
          : authState.isAuthenticated && authState.user != null
              ? (authState.user!.isStaff ? const StaffDashboard() : const StudentDashboard())
              : const GetStartedScreen(),
      routes: {
        '/get-started': (context) => const GetStartedScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/student-dashboard': (context) => const StudentDashboard(),
        '/staff-dashboard': (context) => const StaffDashboard(),
      },
    );
  }
}