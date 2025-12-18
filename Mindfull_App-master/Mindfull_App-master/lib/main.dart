import 'package:flutter/material.dart';
import 'package:mindful/resource_screen.dart';
import 'package:mindful/splash_screen.dart';
import 'package:mindful/login_page.dart';
import 'package:mindful/register_page.dart';
import 'package:mindful/chat_screen.dart';
import 'package:mindful/face_detection.dart';
import 'package:mindful/results_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://lerzabsngwcxgmbvfsyp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxlcnphYnNuZ3djeGdtYnZmc3lwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ4NDczMjMsImV4cCI6MjA4MDQyMzMyM30.LbIA8bwu5P63aGxi-k5IDByKjzuEgRF6Z8cytAPtoLE',               // your Supabase anon/public key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,


      initialRoute: '/splash',


      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/chat': (context) => const MindfulAIScreen(),
        '/emotion': (context) => const EmotionDetectionScreen(),
        '/resources': (context) => const ResourcesScreen(),
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
