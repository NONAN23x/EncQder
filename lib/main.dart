import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/encqder_app.dart';
import 'app/theme_controller.dart';
import 'data/backup_service.dart';
import 'data/history_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final directory = await getApplicationDocumentsDirectory();
  final historyStore = HistoryStore(directory: directory);
  try {
    await historyStore.initialize();
  } catch (error, stackTrace) {
    debugPrint('History initialization failed: $error\n$stackTrace');
  }

  var themeController = ThemeController();
  try {
    themeController = await ThemeController.load();
  } catch (error, stackTrace) {
    debugPrint('Theme initialization failed: $error\n$stackTrace');
  }

  final backupService = BackupService(historyStore: historyStore);
  try {
    await backupService.clearTemporaryExports(await getTemporaryDirectory());
  } catch (error, stackTrace) {
    debugPrint('Temporary backup cleanup failed: $error\n$stackTrace');
  }
  runApp(
    EncQderApp(
      historyStore: historyStore,
      backupService: backupService,
      themeController: themeController,
    ),
  );
}
