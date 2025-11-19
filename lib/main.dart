import 'package:flutter/material.dart';
import 'screens/signup_page.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/dictation_page.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const DictationApp());
}

class DictationApp extends StatelessWidget {
  const DictationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoiceVault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: AppRoutes.signup,
      routes: {
        AppRoutes.signup: (context) => const SignupPage(),
        AppRoutes.login: (context) => const LoginPage(),
        AppRoutes.home: (context) => const HomePage(),
        // dictation can still have a placeholder for now
        AppRoutes.dictation: (context) =>
        const DictationPage(userEmail: 'dom@gmail.com'),
        // ❌ REMOVE THIS: AppRoutes.view
      },
    );
  }
}
