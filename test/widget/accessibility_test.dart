import 'package:encqder/domain/qr_models.dart';
import 'package:encqder/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestEnvironment environment;

  setUp(() async {
    environment = await TestEnvironment.create();
    await environment.historyStore.saveItem(
      'https://example.com/accessibility',
      kind: QrKind.text,
      label: 'Accessible example',
    );
  });

  tearDown(() async {
    await environment.dispose();
  });

  testWidgets('History remains usable at 200 percent text scaling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: HomeScreen(
          historyStore: environment.historyStore,
          backupService: environment.backupService,
          themeController: environment.themeController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accessible example'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary History controls meet tap-target and label guidance', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          historyStore: environment.historyStore,
          backupService: environment.backupService,
          themeController: environment.themeController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}
