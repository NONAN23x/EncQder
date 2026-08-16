import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/qr_models.dart';

typedef ExternalUriLauncher = Future<bool> Function(Uri uri);

abstract final class PayloadActions {
  static String? labelFor(ParsedQrPayload payload) {
    if (payload.wifi != null) return 'Wi-Fi details';
    if (payload.upi != null) return 'Pay with UPI';
    if (payload.webUri != null) return 'Open link';
    return null;
  }

  static Future<void> perform(
    BuildContext context,
    ParsedQrPayload payload, {
    ExternalUriLauncher? launcher,
  }) async {
    if (payload.wifi case final wifi?) {
      await _showWifi(context, wifi);
      return;
    }
    if (payload.upi case final upi?) {
      final confirmed = await _confirmUpi(context, upi);
      if (!confirmed || !context.mounted) return;
      await _launch(context, payload.actionableUri!, launcher);
      return;
    }
    if (payload.webUri case final uri?) {
      if (uri.scheme == 'http') {
        final confirmed = await _confirmHttp(context, uri);
        if (!confirmed || !context.mounted) return;
      }
      await _launch(context, uri, launcher);
    }
  }

  static Future<void> _showWifi(BuildContext context, WifiPayload wifi) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wi-Fi details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Network', style: Theme.of(context).textTheme.labelMedium),
            SelectableText(wifi.ssid),
            const SizedBox(height: 16),
            Text('Security', style: Theme.of(context).textTheme.labelMedium),
            Text(wifi.security.wireName.toUpperCase()),
            if (wifi.password case final password?) ...[
              const SizedBox(height: 16),
              Text('Password', style: Theme.of(context).textTheme.labelMedium),
              SelectableText(password),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          if (wifi.password case final password?)
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: password));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password copied.')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy password'),
            ),
        ],
      ),
    );
  }

  static Future<bool> _confirmUpi(BuildContext context, UpiPayload upi) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Open UPI payment?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(upi.payeeName ?? upi.payeeAddress),
                if (upi.payeeName != null) Text(upi.payeeAddress),
                if (upi.amount != null) ...[
                  const SizedBox(height: 12),
                  Text('Amount: ₹${upi.amount}'),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Verify the payee in your payment app before approving.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<bool> _confirmHttp(BuildContext context, Uri uri) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Open insecure link?'),
            content: Text(
              '${uri.host} uses HTTP, so information sent to it is not encrypted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Open anyway'),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<void> _launch(
    BuildContext context,
    Uri uri,
    ExternalUriLauncher? launcher,
  ) async {
    try {
      final opened =
          await (launcher?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (opened || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No app can open ${uri.scheme} links.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open this link: $error')),
      );
    }
  }
}
