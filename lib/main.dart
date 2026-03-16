import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const EncQderApp());
}

class EncQderApp extends StatelessWidget {
  const EncQderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EncQder',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Natively adapt to light/dark
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
          primary: Colors.black,
          secondary: Colors.grey[800]!,
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineMedium: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
          bodyLarge: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0.2),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
          primary: Colors.white,
          secondary: Colors.grey[300]!,
          surface: const Color(0xFF1E1E1E),
          onSurface: Colors.white70,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineMedium: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
          bodyLarge: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0.2),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white70),
          titleTextStyle: TextStyle(
            color: Colors.white70,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF2C2C2C), width: 1),
          ),
          color: const Color(0xFF1E1E1E),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          contentPadding: const EdgeInsets.all(20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2C2C2C), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2C2C2C), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
