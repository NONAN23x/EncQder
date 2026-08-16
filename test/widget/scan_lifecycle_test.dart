import 'dart:async';

import 'package:encqder/domain/qr_models.dart';
import 'package:encqder/features/scan/scan_screen.dart';
import 'package:encqder/features/scan/scanner_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> setLifecycle(
    WidgetTester tester,
    AppLifecycleState state,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required FakeScanner scanner,
    required bool active,
    Future<void> Function(String, QrKind, QrOrigin)? onSave,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ScanScreen(
          active: active,
          scanner: scanner,
          onIdle: () {},
          onSave: onSave ?? (_, _, _) async {},
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('starts only while active and resumed, then stops promptly', (
    tester,
  ) async {
    final scanner = FakeScanner();
    await setLifecycle(tester, AppLifecycleState.paused);

    await pumpScreen(tester, scanner: scanner, active: true);
    expect(scanner.events, isEmpty);

    await setLifecycle(tester, AppLifecycleState.resumed);
    expect(scanner.events, ['start']);
    expect(find.byKey(FakeScanner.previewKey), findsOneWidget);

    await pumpScreen(tester, scanner: scanner, active: false);
    expect(scanner.events, ['start', 'stop']);
    expect(find.text('Camera paused'), findsOneWidget);

    await pumpScreen(tester, scanner: scanner, active: true);
    expect(scanner.events, ['start', 'stop', 'start']);

    await setLifecycle(tester, AppLifecycleState.paused);
    expect(scanner.events, ['start', 'stop', 'start', 'stop']);
  });

  testWidgets('serializes start and stop while result sheet is visible', (
    tester,
  ) async {
    final startGate = Completer<void>();
    final scanner = FakeScanner(startGate: startGate);
    final saved = <(String, QrKind, QrOrigin)>[];
    await setLifecycle(tester, AppLifecycleState.resumed);
    await pumpScreen(
      tester,
      scanner: scanner,
      active: true,
      onSave: (data, kind, origin) async => saved.add((data, kind, origin)),
    );
    expect(scanner.events, ['start']);

    final detection = scanner.detect('hello from camera');
    await tester.pump();
    expect(scanner.events, ['start']);
    expect(find.text('Scanned content'), findsNothing);

    startGate.complete();
    await tester.pumpAndSettle();
    expect(scanner.events, ['start', 'stop']);
    expect(find.text('Scanned content'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await detection;

    expect(scanner.events, ['start', 'stop', 'start']);
    expect(saved, [('hello from camera', QrKind.text, QrOrigin.scanned)]);
  });

  testWidgets('shows retry UI when camera start fails and recovers', (
    tester,
  ) async {
    final scanner = FakeScanner(startFailures: 1);
    await setLifecycle(tester, AppLifecycleState.resumed);
    await pumpScreen(tester, scanner: scanner, active: true);
    await tester.pumpAndSettle();

    expect(scanner.events, ['start']);
    expect(find.text('Camera unavailable'), findsOneWidget);
    expect(find.text('Retry camera'), findsOneWidget);

    await tester.tap(find.text('Retry camera'));
    await tester.pumpAndSettle();

    expect(scanner.events, ['start', 'start']);
    expect(find.byKey(FakeScanner.previewKey), findsOneWidget);
    expect(find.text('Camera unavailable'), findsNothing);
  });
}

final class FakeScanner implements ScannerBoundary {
  FakeScanner({this.startGate, this.startFailures = 0});

  static const previewKey = Key('fake-scanner-preview');

  final Completer<void>? startGate;
  int startFailures;
  final List<String> events = <String>[];
  ScannerDetectionCallback? _onDetect;

  Future<void> detect(String data) {
    final callback = _onDetect;
    if (callback == null) throw StateError('Preview is not mounted.');
    return callback(ScanCapture(data: data));
  }

  @override
  Future<void> start() async {
    events.add('start');
    if (startFailures > 0) {
      startFailures -= 1;
      throw const ScannerException('cameraUnavailable');
    }
    await startGate?.future;
  }

  @override
  Future<void> stop() async {
    events.add('stop');
  }

  @override
  Future<String?> analyzeImage(String path) async => null;

  @override
  Widget buildPreview({
    required Rect scanWindow,
    required ScannerDetectionCallback onDetect,
    required ScannerErrorBuilder errorBuilder,
    required ScannerOverlayBuilder overlayBuilder,
  }) {
    _onDetect = onDetect;
    return const ColoredBox(key: previewKey, color: Colors.black);
  }

  @override
  Future<void> dispose() async {
    events.add('dispose');
  }
}
