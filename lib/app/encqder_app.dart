import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import '../data/backup_service.dart';
import '../data/history_store.dart';
import '../features/home/home_screen.dart';
import 'app_theme.dart';
import 'theme_controller.dart';

class EncQderApp extends StatelessWidget {
  const EncQderApp({
    super.key,
    required this.historyStore,
    required this.backupService,
    required this.themeController,
  });

  final HistoryStore historyStore;
  final BackupService backupService;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            final lightScheme =
                lightDynamic?.harmonized() ??
                ColorScheme.fromSeed(
                  seedColor: Colors.black,
                  brightness: Brightness.light,
                );
            final darkScheme =
                darkDynamic?.harmonized() ??
                ColorScheme.fromSeed(
                  seedColor: Colors.white,
                  brightness: Brightness.dark,
                );
            return MaterialApp(
              title: 'EncQder',
              debugShowCheckedModeBanner: false,
              themeMode: themeController.themeMode,
              theme: AppTheme.build(lightScheme),
              darkTheme: AppTheme.build(darkScheme),
              home: HomeScreen(
                historyStore: historyStore,
                backupService: backupService,
                themeController: themeController,
              ),
            );
          },
        );
      },
    );
  }
}
