import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

abstract final class QrStyle {
  static QrCode encode(String data) {
    Object? lastError;
    for (final level in const [
      QrErrorCorrectLevel.H,
      QrErrorCorrectLevel.Q,
      QrErrorCorrectLevel.M,
      QrErrorCorrectLevel.L,
    ]) {
      try {
        final encoded = QrCode.fromData(data: data, errorCorrectLevel: level);
        // `QrCode.fromData` defers its final capacity check until an image is
        // materialized. Force that work here so the next correction level is
        // actually attempted for long payloads.
        QrImage(encoded);
        return encoded;
      } catch (error) {
        lastError = error;
      }
    }
    throw ArgumentError.value(data, 'data', 'Payload is too large: $lastError');
  }

  static PrettyQrDecoration decoration(BuildContext _) {
    return const PrettyQrDecoration(
      // Keep the conservative square fallback until styled modules are
      // verified by decoder tests on the supported Android API matrix.
      shape: PrettyQrSquaresSymbol(color: Colors.black),
      background: Colors.white,
      quietZone: PrettyQrQuietZone.modules(4),
    );
  }
}
