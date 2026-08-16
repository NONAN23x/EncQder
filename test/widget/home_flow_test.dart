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
  });

  tearDown(() async {
    await environment.dispose();
  });

  Widget app() => MaterialApp(
    home: HomeScreen(
      historyStore: environment.historyStore,
      backupService: environment.backupService,
      themeController: environment.themeController,
    ),
  );

  testWidgets('starts on History and exposes all navigation destinations', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Create'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Your history is empty'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-bottom-navigation')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('created QR preview and store update appear in History', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-create')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Text / URL').first);
    await tester.pumpAndSettle();

    const payload = 'Reactive history payload';
    await tester.enterText(find.byType(TextField).first, payload);
    await tester.pump();
    final previewButton = find.widgetWithText(FilledButton, 'Preview QR code');
    expect(previewButton, findsOneWidget);
    expect(tester.widget<FilledButton>(previewButton).onPressed, isNotNull);
    await tester.ensureVisible(previewButton);
    await tester.tap(previewButton);
    await tester.pumpAndSettle();

    expect(find.text('Preview'), findsOneWidget);
    expect(find.text(payload), findsWidgets);
    final saveButton = find.widgetWithText(FilledButton, 'Save');
    expect(saveButton, findsOneWidget);
    await tester.ensureVisible(saveButton);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    await tester.runAsync(
      () => environment.historyStore.saveItem(payload, kind: QrKind.text),
    );
    Navigator.of(tester.element(find.text('Preview'))).pop();
    await tester.pumpAndSettle();

    expect(environment.historyStore.items, hasLength(1));
    expect(environment.historyStore.items.single.data, payload);

    await tester.tap(find.byKey(const ValueKey('nav-history')));
    await tester.pumpAndSettle();

    expect(find.text(payload), findsOneWidget);
    expect(find.text('QR Code'), findsOneWidget);
    expect(find.byKey(const ValueKey('history-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
