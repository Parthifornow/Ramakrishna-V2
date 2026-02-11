import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/cache/cache_manager.dart';
import 'core/session/session_manager.dart';
import 'services/network_service.dart';  // Add this import
import 'services/api_service.dart';      // Add this import
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/get_started.dart';
import 'screens/staff_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Initializing app...');

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    // Initialize NetworkService (CRITICAL - must be before ApiService)
    NetworkService().init();
    print('✅ NetworkService initialized');

    // Initialize ApiService
    ApiService.init();
    print('✅ ApiService initialized');

    // Initialize Cache Manager
    await CacheManager().init();
    print('✅ CacheManager initialized');

    // Initialize Session Manager
    await SessionManager().init();
    print('✅ SessionManager initialized');

    print('✅ All services initialized successfully');

    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e) {
    print('❌ Initialization error: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'School Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: false,
      ),
      home: const SplashScreen(),
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