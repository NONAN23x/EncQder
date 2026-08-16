// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:encqder/app/theme_controller.dart';
import 'package:encqder/data/backup_service.dart';
import 'package:encqder/data/history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Isolated on-disk history and in-memory preferences for widget tests.
final class TestEnvironment {
  TestEnvironment._({
    required this.directory,
    required this.historyStore,
    required this.backupService,
    required this.themeController,
    required this.asyncPreferences,
  });

  final Directory directory;
  final HistoryStore historyStore;
  final BackupService backupService;
  final ThemeController themeController;
  final SharedPreferencesAsync asyncPreferences;

  static Future<TestEnvironment> create({
    Map<String, Object> initialAsyncPreferences = const <String, Object>{},
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final legacyPreferences = await SharedPreferences.getInstance();

    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(initialAsyncPreferences);
    final asyncPreferences = SharedPreferencesAsync();

    final directory = await Directory.systemTemp.createTemp(
      'encqder-widget-test-',
    );
    var nextId = 0;
    final historyStore = HistoryStore(
      directory: directory,
      clock: () => DateTime.utc(2026, 7, 17, 12, nextId),
      idFactory: () => 'widget-id-${++nextId}',
      preferencesProvider: () async => legacyPreferences,
    );
    await historyStore.initialize();

    final themeController = await ThemeController.load(
      preferences: asyncPreferences,
    );
    return TestEnvironment._(
      directory: directory,
      historyStore: historyStore,
      backupService: BackupService(historyStore: historyStore),
      themeController: themeController,
      asyncPreferences: asyncPreferences,
    );
  }

  Future<void> dispose() async {
    historyStore.dispose();
    themeController.dispose();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
