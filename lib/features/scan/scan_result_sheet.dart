import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/qr_models.dart';
import '../../shared/qr/payload_actions.dart';

class ScanResultSheet extends StatefulWidget {
  const ScanResultSheet({
    super.key,
    required this.payload,
    required this.onSave,
    this.uriLauncher,
  });

  final ParsedQrPayload payload;
  final Future<void> Function() onSave;
  final ExternalUriLauncher? uriLauncher;

  @override
  State<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<ScanResultSheet> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save QR code: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionLabel = PayloadActions.labelFor(widget.payload);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Scanned content',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: SelectableText(widget.payload.rawData),
              ),
            ),
            const SizedBox(height: 20),
            if (actionLabel != null) ...[
              FilledButton.tonalIcon(
                onPressed: () => PayloadActions.perform(
                  context,
                  widget.payload,
                  launcher: widget.uriLauncher,
                ),
                icon: Icon(
                  widget.payload.wifi != null
                      ? Icons.wifi_rounded
                      : widget.payload.upi != null
                      ? Icons.account_balance_wallet_rounded
                      : Icons.open_in_new_rounded,
                ),
                label: Text(actionLabel),
              ),
              const SizedBox(height: 12),
            ],
            OverflowBar(
              alignment: MainAxisAlignment.center,
              overflowAlignment: OverflowBarAlignment.center,
              spacing: 12,
              overflowSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(text: widget.payload.rawData),
                  ),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share'),
                ),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save'),
                ),
              ],
            ),
            if (_saving) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
