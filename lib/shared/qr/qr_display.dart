import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import 'qr_style.dart';

class QrDisplay extends StatelessWidget {
  const QrDisplay({super.key, required this.data, this.size = 200});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final QrCode encoded;
    try {
      encoded = QrStyle.encode(data);
    } catch (_) {
      return Semantics(
        label: 'QR code could not be rendered because the payload is too large',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.qr_code_2_rounded,
            size: size * 0.4,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      image: true,
      label: 'Open full-screen QR code',
      hint: 'Double tap to enlarge for scanning',
      child: GestureDetector(
        onTap: () => showFullscreenQr(context, data),
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: PrettyQrView(
            qrImage: QrImage(encoded),
            decoration: QrStyle.decoration(context),
          ),
        ),
      ),
    );
  }
}

Future<void> showFullscreenQr(BuildContext context, String data) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss full-screen QR code',
    barrierColor: Colors.black87,
    pageBuilder: (dialogContext, _, _) {
      final screen = MediaQuery.sizeOf(dialogContext);
      // On phones in portrait this reaches edge to edge; in landscape it stays
      // fully visible instead of extending below the screen.
      final codeSize = screen.shortestSide;
      final encoded = QrStyle.encode(data);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(dialogContext).pop(),
        child: Semantics(
          button: true,
          label: 'Full-screen QR code',
          hint: 'Tap anywhere to dismiss',
          child: Center(
            child: SizedBox(
              width: codeSize,
              height: codeSize,
              child: PrettyQrView(
                qrImage: QrImage(encoded),
                decoration: QrStyle.decoration(dialogContext),
              ),
            ),
          ),
        ),
      );
    },
  );
}
