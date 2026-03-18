import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'screens/home_screen.dart';
import 'services/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  runApp(
    EncQderApp(themeProvider: ThemeProvider()),
  );
}

class EncQderApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  
  const EncQderApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            ColorScheme lightScheme;
            ColorScheme darkScheme;

            if (lightDynamic != null && darkDynamic != null) {
              lightScheme = lightDynamic.harmonized();
              // To maintain the light theme background feeling
              lightScheme = lightScheme.copyWith(
                surface: Colors.white,
              );
              
              darkScheme = darkDynamic.harmonized();
              // To maintain the dark theme background feeling
              darkScheme = darkScheme.copyWith(
                surface: const Color(0xFF1E1E1E),
              );
            } else {
              lightScheme = ColorScheme.fromSeed(
                seedColor: Colors.black,
                brightness: Brightness.light,
                primary: Colors.black,
                secondary: Colors.grey[800]!,
                surface: Colors.white,
                onSurface: Colors.black87,
              );
              darkScheme = ColorScheme.fromSeed(
                seedColor: Colors.white,
                brightness: Brightness.dark,
                primary: Colors.white,
                secondary: Colors.grey[300]!,
                surface: const Color(0xFF1E1E1E),
                onSurface: Colors.white70,
              );
            }

            return MaterialApp(
              title: 'EncQder',
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.themeMode, // Controlled dynamically
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                scaffoldBackgroundColor: const Color(0xFFF8F9FA),
                colorScheme: lightScheme,
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
                    backgroundColor: lightScheme.primary,
                    foregroundColor: lightScheme.onPrimary,
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
                    borderSide: BorderSide(color: lightScheme.primary, width: 2),
                  ),
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: const Color(0xFF121212),
                colorScheme: darkScheme,
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
                    backgroundColor: darkScheme.primary,
                    foregroundColor: darkScheme.onPrimary,
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
                    borderSide: BorderSide(color: darkScheme.primary, width: 2),
                  ),
                ),
              ),
              home: HomeScreen(themeProvider: themeProvider),
            );
          },
        );
      },
    );
  }
}
