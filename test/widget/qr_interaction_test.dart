import 'package:encqder/domain/qr_models.dart';
import 'package:encqder/features/create/create_forms.dart';
import 'package:encqder/shared/qr/collapsible_payload_text.dart';
import 'package:encqder/shared/qr/qr_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UPI preview stays disabled until an ID is entered', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpiQrForm(
            suggestions: const <String>[],
            onForgetSuggestion: (_) {},
            onPreview: (_, QrKind _) {},
          ),
        ),
      ),
    );

    final button = find.widgetWithText(FilledButton, 'Preview payment QR code');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'person@bank');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('QR code opens full screen and closes from any tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: QrDisplay(data: 'encqder')),
        ),
      ),
    );

    await tester.tap(find.byType(QrDisplay));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Full-screen QR code'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Full-screen QR code'), findsNothing);
  });

  testWidgets('long QR content toggles between three lines and expanded', (
    tester,
  ) async {
    const payload =
        'This is a deliberately long QR payload that needs more than three '
        'lines when displayed in a narrow QR preview card.';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 140,
            child: CollapsiblePayloadText(data: payload),
          ),
        ),
      ),
    );

    Text payloadText() => tester.widget<Text>(find.text(payload));
    expect(payloadText().maxLines, 3);
    expect(payloadText().overflow, TextOverflow.ellipsis);

    await tester.tap(find.byKey(const ValueKey('toggle-qr-payload')));
    await tester.pump();
    expect(payloadText().maxLines, isNull);

    await tester.tap(find.byKey(const ValueKey('toggle-qr-payload')));
    await tester.pump();
    expect(payloadText().maxLines, 3);
  });
}
