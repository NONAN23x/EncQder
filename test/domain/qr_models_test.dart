import 'package:encqder/domain/qr_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('wire enums', () {
    test('parse current and legacy spellings case-insensitively', () {
      expect(QrKind.tryParse('WIFI'), QrKind.wifi);
      expect(QrKind.tryParse('wi-fi'), QrKind.wifi);
      expect(QrOrigin.tryParse('SCANNED'), QrOrigin.scanned);
      expect(WifiSecurity.tryParse('nopass'), WifiSecurity.open);
      expect(WifiSecurity.tryParse('WPA3'), WifiSecurity.wpa);
    });

    test('fall back predictably for unknown persisted values', () {
      expect(QrKind.parse('unknown'), QrKind.text);
      expect(QrOrigin.parse(null), QrOrigin.generated);
      expect(
        WifiSecurity.parse('unknown', fallback: WifiSecurity.open),
        WifiSecurity.open,
      );
    });
  });

  group('QrItem', () {
    final localTime = DateTime.parse('2026-01-02T03:04:05+05:30');

    test('serializes the v2 item shape with a UTC timestamp', () {
      final item = QrItem(
        id: 'item-1',
        data: 'upi://pay?pa=alice%40upi&cu=INR',
        createdAt: localTime,
        origin: QrOrigin.scanned,
        kind: QrKind.upi,
        label: 'Lunch',
        hiddenFromUpiSuggestions: true,
      );

      expect(item.toJson(), <String, dynamic>{
        'id': 'item-1',
        'data': 'upi://pay?pa=alice%40upi&cu=INR',
        'createdAt': '2026-01-01T21:34:05.000Z',
        'origin': 'scanned',
        'kind': 'upi',
        'label': 'Lunch',
        'hiddenFromUpiSuggestions': true,
      });
      expect(QrItem.fromJson(item.toJson()), item);
    });

    test('reads legacy field names and a flattened hidden flag', () {
      final item = QrItem.fromJson(<String, dynamic>{
        'id': 1700000000000,
        'data': 'WIFI:T:nopass;S:Cafe;;',
        'createdAt': '2026-01-02T03:04:05+05:30',
        'originType': 'scanned',
        'dataType': 'WIFI',
        'label': 'Cafe Wi-Fi',
        'hiddenFromSuggestions': true,
      });

      expect(item.id, '1700000000000');
      expect(item.createdAt.isUtc, isTrue);
      expect(item.origin, QrOrigin.scanned);
      expect(item.kind, QrKind.wifi);
      expect(item.hiddenFromUpiSuggestions, isTrue);
    });

    test('reads the hidden flag from legacy extraData', () {
      final item = QrItem.fromJson(<String, dynamic>{
        'id': 'item-2',
        'data': 'upi://pay?pa=alice%40upi',
        'createdAt': 1767303245000,
        'dataType': 'UPI',
        'extraData': <String, dynamic>{'hiddenFromSuggestions': true},
      });

      expect(item.kind, QrKind.upi);
      expect(item.hiddenFromUpiSuggestions, isTrue);
      expect(item.label, isEmpty);
    });

    test('copyWith preserves identity while replacing selected values', () {
      final original = QrItem(
        id: 'item-1',
        data: 'hello',
        createdAt: localTime,
        kind: QrKind.text,
        label: 'Old label',
      );

      final updated = original.copyWith(
        label: 'New label',
        hiddenFromUpiSuggestions: true,
      );

      expect(updated.id, original.id);
      expect(updated.data, original.data);
      expect(updated.createdAt, original.createdAt);
      expect(updated.label, 'New label');
      expect(updated.hiddenFromUpiSuggestions, isTrue);
      expect(original.label, 'Old label');
    });

    test('rejects malformed required values and flag types', () {
      final valid = <String, dynamic>{
        'id': 'item-1',
        'data': 'hello',
        'createdAt': '2026-01-02T03:04:05Z',
      };

      expect(
        () => QrItem.fromJson(<String, dynamic>{...valid, 'id': ''}),
        throwsFormatException,
      );
      expect(
        () => QrItem.fromJson(<String, dynamic>{
          ...valid,
          'createdAt': 'not-a-date',
        }),
        throwsFormatException,
      );
      expect(
        () => QrItem.fromJson(<String, dynamic>{
          ...valid,
          'hiddenFromSuggestions': 'yes',
        }),
        throwsFormatException,
      );
    });
  });
}
