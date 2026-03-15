import 'package:flutter/material.dart';
import 'package:mindful/app_theme.dart';
import 'package:mindful/resource_screen.dart';
import 'package:mindful/splash_screen.dart';
import 'package:mindful/login_page.dart';
import 'package:mindful/register_page.dart';
import 'package:mindful/dashboard_screen.dart';
import 'package:mindful/mood_tracker_screen.dart';
import 'package:mindful/meditation_screen.dart';
import 'package:mindful/face_detection.dart';
import 'package:mindful/results_screen.dart';
import 'package:mindful/screens/notifications_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindCare AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      initialRoute: '/splash',

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/chat': (context) => const DashboardScreen(),
        '/emotion': (context) => const EmotionDetectionScreen(),
        '/resources': (context) => const ResourcesScreen(),
        '/mood-tracker': (context) => const MoodTrackerScreen(),
        '/meditation': (context) => const MeditationScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/results': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ResultsScreen(
            screeningResult: args['result'],
            allResults: args['allResults'],
          );
        },
      },
    );
  }
}
