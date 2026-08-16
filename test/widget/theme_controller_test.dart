import 'package:encqder/app/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads, notifies, and persists the selected theme', () async {
    final environment = await TestEnvironment.create(
      initialAsyncPreferences: const <String, Object>{'theme_mode': 'dark'},
    );
    addTearDown(environment.dispose);

    expect(environment.themeController.themeMode, ThemeMode.dark);

    var notifications = 0;
    environment.themeController.addListener(() => notifications++);
    await environment.themeController.setThemeMode(ThemeMode.light);

    expect(environment.themeController.themeMode, ThemeMode.light);
    expect(notifications, 1);
    expect(
      await environment.asyncPreferences.getString('theme_mode'),
      ThemeMode.light.name,
    );

    final reloaded = await ThemeController.load(
      preferences: environment.asyncPreferences,
    );
    addTearDown(reloaded.dispose);
    expect(reloaded.themeMode, ThemeMode.light);
  });

  test('unknown stored values safely fall back to the system theme', () async {
    final environment = await TestEnvironment.create(
      initialAsyncPreferences: const <String, Object>{
        'theme_mode': 'not-a-theme',
      },
    );
    addTearDown(environment.dispose);

    expect(environment.themeController.themeMode, ThemeMode.system);
  });
}
