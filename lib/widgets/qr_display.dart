import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class QrDisplay extends StatelessWidget {
  final String data;
  final double size;

  const QrDisplay({super.key, required this.data, this.size = 200.0});

  @override
  Widget build(BuildContext context) {
    // Determine qr color based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qrColor = isDark ? Colors.white : Colors.black;
    
    final qrBrush = PrettyQrBrush.gradient(
      gradient: RadialGradient(
        colors: [
          isDark ? Colors.blue.shade200 : Colors.blue.shade800,
          qrColor,
        ],
      ),
    );

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
        child: SizedBox(
          width: size,
          height: size,
          child: PrettyQrView.data(
            data: data,
            errorCorrectLevel: QrErrorCorrectLevel.Q,
            decoration: PrettyQrDecoration(
              // ignore: experimental_member_use
              shape: PrettyQrShape.custom(
                PrettyQrDotsSymbol(
                  color: qrBrush,
                  density: 0.8,
                  unifiedFinderPattern: false,
                  unifiedAlignmentPatterns: false,
                ),
                finderPattern: PrettyQrSmoothSymbol(
                  color: qrBrush,
                  roundFactor: 1.0,
                ),
                alignmentPatterns: PrettyQrSmoothSymbol(
                  color: qrBrush,
                  roundFactor: 1.0,
                ),
              ),
              background: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}
