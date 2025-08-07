import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app_navigator.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
  );

  runApp(const QuickPostApp());
}

class QuickPostApp extends StatelessWidget {
  const QuickPostApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4B69FF),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4B69FF),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
    return MaterialApp(
      title: 'QuickPost',
      theme: baseTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: quickpostRouteGenerator,
    );
  }
}

// Import custom navigator

