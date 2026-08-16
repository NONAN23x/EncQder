// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:encqder/app/encqder_app.dart';
import 'package:encqder/app/theme_controller.dart';
import 'package:encqder/data/backup_service.dart';
import 'package:encqder/data/history_store.dart';
import 'package:encqder/domain/qr_models.dart';
import 'package:encqder/domain/qr_payload_codec.dart';
import 'package:encqder/shared/qr/qr_image_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create, save, and revisit history without camera hardware', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final legacyPreferences = await SharedPreferences.getInstance();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final asyncPreferences = SharedPreferencesAsync();
    final directory = await Directory.systemTemp.createTemp(
      'encqder-integration-',
    );
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    var nextId = 0;
    final historyStore = HistoryStore(
      directory: directory,
      idFactory: () => 'smoke-id-${++nextId}',
      preferencesProvider: () async => legacyPreferences,
    );
    await historyStore.initialize();
    addTearDown(historyStore.dispose);
    final themeController = ThemeController(
      initialMode: ThemeMode.light,
      preferences: asyncPreferences,
    );
    addTearDown(themeController.dispose);

    await tester.pumpWidget(
      EncQderApp(
        historyStore: historyStore,
        backupService: BackupService(historyStore: historyStore),
        themeController: themeController,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your history is empty'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Text or URL').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'Android integration smoke',
    );
    await tester.pump();
    final previewButton = find.widgetWithText(FilledButton, 'Preview QR code');
    await tester.ensureVisible(previewButton);
    await tester.tap(previewButton);
    await tester.pumpAndSettle();
    final saveButton = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (historyStore.items.isEmpty && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump(const Duration(milliseconds: 500));

    expect(historyStore.items.single.data, 'Android integration smoke');

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Android integration smoke'), findsOneWidget);
    expect(find.byKey(const ValueKey('history-list')), findsOneWidget);
  });

  testWidgets('generated PNGs round trip through the Android QR decoder', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox.expand())),
    );
    final context = tester.element(find.byType(Scaffold));
    final scanner = MobileScannerController(autoStart: false);
    addTearDown(scanner.dispose);

    final payloads = <String>[
      'Short Android QR',
      List<String>.filled(80, 'EncQder long payload').join('|'),
      QrPayloadCodec.encodeWifi(
        const WifiPayload(
          ssid: r'Cafe;Guest:\5G',
          security: WifiSecurity.wpa,
          password: r'p@ss;word:\safe',
          hidden: true,
        ),
      ),
      QrPayloadCodec.encodeUpi(
        const UpiPayload(
          payeeAddress: 'person@bank',
          payeeName: 'EncQder Test',
          amount: '25.50',
          transactionNote: 'Android decoder round trip',
        ),
      ),
    ];

    for (var index = 0; index < payloads.length; index++) {
      final payload = payloads[index];
      final file = await QrImageService.createPng(
        context,
        data: payload,
        fileName: 'decoder-$index',
      );
      try {
        final capture = await scanner.analyzeImage(file.path);
        expect(
          capture?.barcodes.map((barcode) => barcode.rawValue),
          contains(payload),
          reason: 'Generated QR payload $index should decode exactly.',
        );
      } finally {
        if (await file.exists()) await file.delete();
      }
    }
  });
}
