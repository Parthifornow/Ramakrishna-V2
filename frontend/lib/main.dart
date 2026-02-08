import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/staff_dashboard.dart';
import 'screens/student_events_screen.dart';
import 'screens/staff_event_screen.dart'; // Fixed: was staff_events_screen.dart
import 'screens/create_event.dart'; // Fixed: was create_event_screen.dart
import 'screens/event_details_screen.dart';
import 'models/user_model.dart';
import 'models/event_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/student-dashboard': (context) => const StudentDashboard(),
        '/staff-dashboard': (context) => const StaffDashboard(),
      },
      onGenerateRoute: (settings) {
        // Handle routes that need arguments
        if (settings.name == '/student-events') {
          final user = settings.arguments as User;
          return MaterialPageRoute(
            builder: (context) => StudentEventsScreen(user: user),
          );
        } else if (settings.name == '/staff-events') {
          final user = settings.arguments as User;
          return MaterialPageRoute(
            builder: (context) => StaffEventsScreen(user: user),
          );
        } else if (settings.name == '/create-event') {
          final user = settings.arguments as User;
          return MaterialPageRoute(
            builder: (context) => CreateEventScreen(user: user),
          );
        } else if (settings.name == '/event-details') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              event: args['event'] as Event,
              user: args['user'] as User,
              onEventUpdated: args['onEventUpdated'] as VoidCallback?,
            ),
          );
        }
        
        return null;
      },
    );
  }
}