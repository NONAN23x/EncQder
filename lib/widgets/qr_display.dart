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
    
    // Subtle dynamic gradient based on user's wallpaper/Material You theme
    final primaryColor = Theme.of(context).colorScheme.primary;
    // Mix the primary color heavily with the qrColor so it's a subtle tint in the center
    final subtleGradientColor = Color.lerp(primaryColor, qrColor, 0.4) ?? primaryColor;
    
    final qrBrush = PrettyQrBrush.gradient(
      gradient: RadialGradient(
        colors: [
          subtleGradientColor,
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
            errorCorrectLevel: QrErrorCorrectLevel.H,
            decoration: PrettyQrDecoration(
              // ignore: experimental_member_use
              shape: PrettyQrShape.custom(
                PrettyQrSmoothSymbol(
                  color: qrBrush,
                  roundFactor: 0.5,
                ),
                finderPattern: PrettyQrSmoothSymbol(
                  color: qrBrush,
                  roundFactor: 0.8,
                ),
                alignmentPatterns: PrettyQrSmoothSymbol(
                  color: qrBrush,
                  roundFactor: 0.8,
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
