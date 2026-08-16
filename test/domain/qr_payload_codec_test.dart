import 'package:encqder/domain/qr_models.dart';
import 'package:encqder/domain/qr_payload_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Wi-Fi payloads', () {
    test('encodes a conventional open network', () {
      expect(
        QrPayloadCodec.encodeWifi(
          const WifiPayload(ssid: 'Cafe', security: WifiSecurity.open),
        ),
        'WIFI:T:nopass;S:Cafe;;',
      );
    });

    test('round trips every reserved character with a hidden network', () {
      const payload = WifiPayload(
        ssid: 'Cafe\\;, :"',
        security: WifiSecurity.wpa,
        password: 'p\\a;ss,:"word',
        hidden: true,
      );

      final encoded = QrPayloadCodec.encodeWifi(payload);

      expect(encoded, contains(r'S:Cafe\\\;\, \:\";'));
      expect(encoded, contains(r'P:p\\a\;ss\,\:\"word;'));
      expect(encoded, endsWith('H:true;;'));
      expect(QrPayloadCodec.parseWifi(encoded), payload);
    });

    test('uses an escape-aware state machine while parsing', () {
      final parsed = QrPayloadCodec.parseWifi(
        r'WIFI:T:WPA;S:Office\; East;P:a\:b\,c\\d\"e;;',
      );

      expect(
        parsed,
        const WifiPayload(
          ssid: 'Office; East',
          security: WifiSecurity.wpa,
          password: 'a:b,c\\d"e',
        ),
      );
    });

    test('accepts common security aliases and a missing open type', () {
      expect(
        QrPayloadCodec.parseWifi('WIFI:T:WPA2;S:Office;P:secret;;')?.security,
        WifiSecurity.wpa,
      );
      expect(
        QrPayloadCodec.parseWifi('WIFI:S:Guest;;'),
        const WifiPayload(ssid: 'Guest', security: WifiSecurity.open),
      );
    });

    test('rejects invalid inputs without throwing', () {
      const invalid = <String>[
        'not wifi',
        'WIFI:T:WPA;S:;P:secret;;',
        'WIFI:T:WPA;S:Office;;',
        'WIFI:T:unknown;S:Office;;',
        'WIFI:T:nopass;S:One;S:Two;;',
        'WIFI:T:nopass;S:Office;H:perhaps;;',
        r'WIFI:T:nopass;S:bad\escape;;',
        'WIFI:T:nopass;S:trailing\\',
      ];

      for (final value in invalid) {
        expect(QrPayloadCodec.parseWifi(value), isNull, reason: value);
      }
    });

    test('rejects invalid values during encoding', () {
      expect(
        () => QrPayloadCodec.encodeWifi(
          const WifiPayload(ssid: '', security: WifiSecurity.open),
        ),
        throwsArgumentError,
      );
      expect(
        () => QrPayloadCodec.encodeWifi(
          const WifiPayload(ssid: 'Office', security: WifiSecurity.wpa),
        ),
        throwsArgumentError,
      );
    });
  });

  group('UPI payloads', () {
    test('builds encoded URIs and round trips supported fields', () {
      const payload = UpiPayload(
        payeeAddress: 'alice@upi',
        payeeName: 'Alice & Co',
        amount: '125.50',
        transactionNote: 'Lunch + tip',
      );

      final encoded = QrPayloadCodec.encodeUpi(payload);
      final uri = Uri.parse(encoded);

      expect(uri.scheme, 'upi');
      expect(uri.host, 'pay');
      expect(uri.queryParameters, <String, String>{
        'pa': 'alice@upi',
        'pn': 'Alice & Co',
        'am': '125.50',
        'cu': 'INR',
        'tn': 'Lunch + tip',
      });
      expect(QrPayloadCodec.parseUpi(encoded), payload);
    });

    test('trims optional values and defaults a missing currency to INR', () {
      expect(
        QrPayloadCodec.parseUpi('upi://pay?pa=alice%40upi&pn=%20Alice%20'),
        const UpiPayload(payeeAddress: 'alice@upi', payeeName: 'Alice'),
      );
    });

    test('validates a structural VPA', () {
      expect(QrPayloadCodec.isValidUpiAddress('a@b'), isTrue);
      expect(
        QrPayloadCodec.isValidUpiAddress('first.last-1@bank.handle'),
        isTrue,
      );
      expect(QrPayloadCodec.isValidUpiAddress('@upi'), isFalse);
      expect(QrPayloadCodec.isValidUpiAddress('.alice@upi'), isFalse);
      expect(QrPayloadCodec.isValidUpiAddress('alice@'), isFalse);
      expect(QrPayloadCodec.isValidUpiAddress('alice @upi'), isFalse);
    });

    test('allows only positive amounts with at most two decimals', () {
      for (final valid in <String>['1', '1.2', '1.23', '000.01']) {
        expect(QrPayloadCodec.isValidUpiAmount(valid), isTrue, reason: valid);
      }
      for (final invalid in <String>[
        '',
        '0',
        '0.00',
        '-1',
        '.50',
        '1.',
        '1.234',
        'NaN',
      ]) {
        expect(
          QrPayloadCodec.isValidUpiAmount(invalid),
          isFalse,
          reason: invalid,
        );
      }
    });

    test('rejects malformed or ambiguous UPI URIs', () {
      const invalid = <String>[
        'upi://collect?pa=alice%40upi',
        'upi://pay?pa=not-a-vpa',
        'upi://pay?pa=alice%40upi&am=0',
        'upi://pay?pa=alice%40upi&am=1.234',
        'upi://pay?pa=alice%40upi&cu=USD',
        'upi://pay?pa=alice%40upi&pa=bob%40upi',
        'upi://pay/path?pa=alice%40upi',
        'upi://pay?pa=alice%40upi#fragment',
      ];

      for (final value in invalid) {
        expect(QrPayloadCodec.parseUpi(value), isNull, reason: value);
      }
    });

    test('throws for invalid generated UPI values', () {
      expect(
        () =>
            QrPayloadCodec.encodeUpi(const UpiPayload(payeeAddress: 'invalid')),
        throwsArgumentError,
      );
      expect(
        () => QrPayloadCodec.encodeUpi(
          const UpiPayload(payeeAddress: 'alice@upi', amount: '1.234'),
        ),
        throwsArgumentError,
      );
      expect(
        () => QrPayloadCodec.encodeUpi(
          const UpiPayload(payeeAddress: 'alice@upi', currency: 'USD'),
        ),
        throwsArgumentError,
      );
    });
  });

  group('action classification', () {
    test('allows only explicit HTTP and HTTPS URIs with a host', () {
      expect(
        QrPayloadCodec.isAllowedWebUri('https://example.com/path'),
        isTrue,
      );
      expect(QrPayloadCodec.isAllowedWebUri('http://localhost:8080'), isTrue);

      for (final blocked in <String>[
        'example.com',
        'file:///tmp/private',
        'intent://scan/#Intent;scheme=zxing;end',
        'javascript:alert(1)',
        'https:///missing-host',
        'https://user:secret@example.com',
      ]) {
        expect(
          QrPayloadCodec.parseAllowedWebUri(blocked),
          isNull,
          reason: blocked,
        );
      }
    });

    test('classifies valid structured payloads and safe text actions', () {
      final wifi = QrPayloadCodec.classify('WIFI:T:nopass;S:Cafe;;');
      final upi = QrPayloadCodec.classify('upi://pay?pa=alice%40upi&cu=INR');
      final https = QrPayloadCodec.classify('https://example.com');
      final http = QrPayloadCodec.classify('http://example.com');
      final unknown = QrPayloadCodec.classify('intent://settings');

      expect(wifi.kind, QrKind.wifi);
      expect(wifi.wifi?.ssid, 'Cafe');
      expect(wifi.isActionable, isFalse);

      expect(upi.kind, QrKind.upi);
      expect(upi.upi?.payeeAddress, 'alice@upi');
      expect(upi.actionableUri?.scheme, 'upi');
      expect(upi.requiresLaunchConfirmation, isTrue);

      expect(https.kind, QrKind.text);
      expect(https.actionableUri, Uri.parse('https://example.com'));
      expect(https.requiresLaunchConfirmation, isFalse);

      expect(http.isActionable, isTrue);
      expect(http.requiresLaunchConfirmation, isTrue);

      expect(unknown.kind, QrKind.text);
      expect(unknown.isActionable, isFalse);
    });

    test('degrades malformed structured payloads to inert text', () {
      final malformedWifi = QrPayloadCodec.classify('WIFI:T:WPA;S:Office;;');
      final malformedUpi = QrPayloadCodec.classify('upi://pay?pa=invalid');

      expect(malformedWifi.kind, QrKind.text);
      expect(malformedWifi.isActionable, isFalse);
      expect(malformedUpi.kind, QrKind.text);
      expect(malformedUpi.isActionable, isFalse);
    });
  });
}
