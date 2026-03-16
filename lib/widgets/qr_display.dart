import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrDisplay extends StatelessWidget {
  final String data;
  final double size;

  const QrDisplay({super.key, required this.data, this.size = 200.0});

  @override
  Widget build(BuildContext context) {
    // Determine qr color based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qrColor = isDark ? Colors.white : Colors.black;
    // For the QR code itself, the background must contrast with the foreground.
    // However, qr_flutter handles transparent backgrounds well.

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).cardTheme.shape is RoundedRectangleBorder
              ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder)
                    .side
                    .color
              : Colors.transparent,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: size,
          eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: qrColor),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: qrColor,
          ),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
