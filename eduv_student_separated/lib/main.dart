import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      theme: ThemeData(
        textTheme: const TextTheme(
          bodyLarge: TextStyle(decoration: TextDecoration.none),
          bodyMedium: TextStyle(decoration: TextDecoration.none),
          bodySmall: TextStyle(decoration: TextDecoration.none),
          titleLarge: TextStyle(decoration: TextDecoration.none),
          titleMedium: TextStyle(decoration: TextDecoration.none),
          titleSmall: TextStyle(decoration: TextDecoration.none),
          headlineLarge: TextStyle(decoration: TextDecoration.none),
          headlineMedium: TextStyle(decoration: TextDecoration.none),
          headlineSmall: TextStyle(decoration: TextDecoration.none),
          labelLarge: TextStyle(decoration: TextDecoration.none),
          labelMedium: TextStyle(decoration: TextDecoration.none),
          labelSmall: TextStyle(decoration: TextDecoration.none),
        ),
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const StudentDashboardPage(),
      },
    );
  }
}