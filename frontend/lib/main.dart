import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/cache/cache_manager.dart';
import 'core/session/session_manager.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/staff_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Cache Manager
  await CacheManager().init();
  
  // Initialize Session Manager
  await SessionManager().init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
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
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/student-dashboard': (context) => const StudentDashboard(),
        '/staff-dashboard': (context) => const StaffDashboard(),
      },
    );
  }
}