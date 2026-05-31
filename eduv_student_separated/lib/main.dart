import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';

/// Global notifier — anyone can call [themeNotifier.value = true/false]
/// to switch the theme without a state management package.
final ValueNotifier<bool> themeNotifier = ValueNotifier(true);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore saved preference on launch
  final prefs = await SharedPreferences.getInstance();
  themeNotifier.value = prefs.getBool('pref_dark_mode') ?? true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _textTheme = TextTheme(
    bodyLarge:     TextStyle(decoration: TextDecoration.none),
    bodyMedium:    TextStyle(decoration: TextDecoration.none),
    bodySmall:     TextStyle(decoration: TextDecoration.none),
    titleLarge:    TextStyle(decoration: TextDecoration.none),
    titleMedium:   TextStyle(decoration: TextDecoration.none),
    titleSmall:    TextStyle(decoration: TextDecoration.none),
    headlineLarge: TextStyle(decoration: TextDecoration.none),
    headlineMedium:TextStyle(decoration: TextDecoration.none),
    headlineSmall: TextStyle(decoration: TextDecoration.none),
    labelLarge:    TextStyle(decoration: TextDecoration.none),
    labelMedium:   TextStyle(decoration: TextDecoration.none),
    labelSmall:    TextStyle(decoration: TextDecoration.none),
  );

  @override
  Widget build(BuildContext context) {
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
          initialRoute: '/login',
          routes: {
            '/login':     (context) => const LoginPage(),
            '/register':  (context) => const RegisterPage(),
            '/dashboard': (context) => const StudentDashboardPage(),
          },
        );
      },
    );
  }
}