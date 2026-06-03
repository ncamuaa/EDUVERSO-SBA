import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';

final ValueNotifier<bool> themeNotifier = ValueNotifier(true);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ddnsqgufmaieofbnnpuq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkbnNxZ3VmbWFpZW9mYm5ucHVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5MzQ1MTMsImV4cCI6MjA5NTUxMDUxM30.ZGGru5bE6Am6hFBvUpyloFm6I5_6aGInK6faF0I-ypM',
  );

  final prefs = await SharedPreferences.getInstance();
  themeNotifier.value = prefs.getBool('pref_dark_mode') ?? true;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _textTheme = TextTheme(
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
  );

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final initialRoute = session != null ? '/dashboard' : '/login';

    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (_, isDark, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            textTheme: _textTheme,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            textTheme: _textTheme,
          ),
          initialRoute: initialRoute,
          routes: {
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/dashboard': (context) => const StudentDashboardPage(),
          },
        );
      },
    );
  }
}