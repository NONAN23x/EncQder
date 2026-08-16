import 'package:encqder/shared/qr/qr_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

void main() {
  test('long payload fully validates before correction level is selected', () {
    final payload = List<String>.filled(80, 'EncQder long payload').join('|');

    final encoded = QrStyle.encode(payload);

    expect(() => QrImage(encoded), returnsNormally);
  });

  test('payload beyond QR capacity fails at the encoding boundary', () {
    final payload = List<String>.filled(4000, 'x').join();

    expect(() => QrStyle.encode(payload), throwsArgumentError);
  });
}
