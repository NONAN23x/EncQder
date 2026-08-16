import 'package:encqder/domain/qr_payload_codec.dart';
import 'package:encqder/features/scan/scan_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPayload(WidgetTester tester, String data) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScanResultSheet(
              payload: QrPayloadCodec.classify(data),
              onSave: () async {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('plain and unsafe text have no contextual launch action', (
    tester,
  ) async {
    await pumpPayload(tester, 'ordinary text');
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Wi-Fi details'), findsNothing);
    expect(find.text('Pay with UPI'), findsNothing);
    expect(find.text('Open link'), findsNothing);

    await pumpPayload(tester, 'intent://settings');
    expect(find.text('Open link'), findsNothing);
  });

  testWidgets('UPI confirmation uses the injected external launcher', (
    tester,
  ) async {
    Uri? launched;
    final payload = QrPayloadCodec.classify(
      'upi://pay?pa=person%40bank&pn=Person&am=25.50&cu=INR',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanResultSheet(
            payload: payload,
            onSave: () async {},
            uriLauncher: (uri) async {
              launched = uri;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pay with UPI'));
    await tester.pumpAndSettle();
    expect(find.text('Open UPI payment?'), findsOneWidget);
    expect(launched, isNull);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(launched, payload.actionableUri);
  });

  testWidgets('result actions remain reachable at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final payload = QrPayloadCodec.classify(
      List.filled(200, 'long text').join(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: ScanResultSheet(payload: payload, onSave: () async {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Save'));
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
  });

  testWidgets('safe web links expose an Open link action', (tester) async {
    await pumpPayload(tester, 'https://example.com/help');

    expect(find.text('Open link'), findsOneWidget);
  });

  testWidgets('Wi-Fi payload exposes details without claiming to connect', (
    tester,
  ) async {
    await pumpPayload(tester, 'WIFI:T:WPA;S:Office;P:secret;;');

    expect(find.text('Wi-Fi details'), findsOneWidget);
    expect(find.text('Connect'), findsNothing);
  });

  testWidgets('UPI payload exposes the explicit payment action', (
    tester,
  ) async {
    await pumpPayload(tester, 'upi://pay?pa=alice%40upi&am=25.00&cu=INR');

    expect(find.text('Pay with UPI'), findsOneWidget);
  });
}
