import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:google_fonts/google_fonts.dart';

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
              lightScheme = lightScheme.copyWith(
                surface: Colors.white,
              );
              
              darkScheme = darkDynamic.harmonized();
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

            final baseLightTextTheme = Typography.material2021().black;
            final baseDarkTextTheme = Typography.material2021().white;

            return MaterialApp(
              title: 'EncQder',
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.themeMode, // Controlled dynamically
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                colorScheme: lightScheme,
                textTheme: GoogleFonts.robotoFlexTextTheme(baseLightTextTheme).copyWith(
                  displayLarge: GoogleFonts.robotoFlex(fontWeight: FontWeight.w700, letterSpacing: -0.5, color: lightScheme.onSurface),
                  headlineMedium: GoogleFonts.robotoFlex(fontWeight: FontWeight.w600, letterSpacing: -0.5, color: lightScheme.onSurface),
                  titleLarge: GoogleFonts.robotoFlex(fontWeight: FontWeight.w600, letterSpacing: -0.2, color: lightScheme.onSurface),
                  bodyLarge: GoogleFonts.robotoFlex(fontWeight: FontWeight.w400, letterSpacing: 0.2, color: lightScheme.onSurface),
                ),
                scaffoldBackgroundColor: lightScheme.surfaceContainerLowest,
                appBarTheme: AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  centerTitle: true,
                  iconTheme: IconThemeData(color: lightScheme.onSurface),
                  titleTextStyle: GoogleFonts.robotoFlex(
                    color: lightScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: GoogleFonts.robotoFlex(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightScheme.primary,
                    foregroundColor: lightScheme.onPrimary,
                    elevation: 1, // Slight elevation for M3
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: GoogleFonts.robotoFlex(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                cardTheme: CardThemeData(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: lightScheme.outlineVariant, width: 1),
                  ),
                  color: lightScheme.surfaceContainerLow,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: lightScheme.surfaceContainerLow,
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: lightScheme.outline, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: lightScheme.outlineVariant, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: lightScheme.primary, width: 2),
                  ),
                ),
                chipTheme: ChipThemeData(
                  backgroundColor: lightScheme.surfaceContainerHigh,
                  side: BorderSide(color: lightScheme.outlineVariant),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  labelStyle: GoogleFonts.robotoFlex(color: lightScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: darkScheme,
                textTheme: GoogleFonts.robotoFlexTextTheme(baseDarkTextTheme).copyWith(
                  displayLarge: GoogleFonts.robotoFlex(fontWeight: FontWeight.w700, letterSpacing: -0.5, color: darkScheme.onSurface),
                  headlineMedium: GoogleFonts.robotoFlex(fontWeight: FontWeight.w600, letterSpacing: -0.5, color: darkScheme.onSurface),
                  titleLarge: GoogleFonts.robotoFlex(fontWeight: FontWeight.w600, letterSpacing: -0.2, color: darkScheme.onSurface),
                  bodyLarge: GoogleFonts.robotoFlex(fontWeight: FontWeight.w400, letterSpacing: 0.2, color: darkScheme.onSurface),
                ),
                scaffoldBackgroundColor: darkScheme.surfaceContainerLowest,
                appBarTheme: AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  centerTitle: true,
                  iconTheme: IconThemeData(color: darkScheme.onSurface),
                  titleTextStyle: GoogleFonts.robotoFlex(
                    color: darkScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: GoogleFonts.robotoFlex(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkScheme.primary,
                    foregroundColor: darkScheme.onPrimary,
                    elevation: 1, // Slight elevation for M3
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: GoogleFonts.robotoFlex(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                cardTheme: CardThemeData(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: darkScheme.outlineVariant, width: 1),
                  ),
                  color: darkScheme.surfaceContainerLow,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: darkScheme.surfaceContainerLow,
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: darkScheme.outline, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: darkScheme.outlineVariant, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: darkScheme.primary, width: 2),
                  ),
                ),
                chipTheme: ChipThemeData(
                  backgroundColor: darkScheme.surfaceContainerHigh,
                  side: BorderSide(color: darkScheme.outlineVariant),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  labelStyle: GoogleFonts.robotoFlex(color: darkScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
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
