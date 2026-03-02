import 'package:flutter/material.dart';
import 'screens/main_layout.dart';

void main() {
  runApp(const PosApp());
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Kasir Desktop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006B5E), // A nice professional teal/green
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Segoe UI', // Good for desktop, can fall back nicely
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006B5E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Segoe UI',
      ),
      themeMode: ThemeMode.system, // Supports both light/dark based on system
      home: const MainLayout(),
    );
  }
}
