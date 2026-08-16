import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/qr_models.dart';
import 'qr_image_service.dart';

class QrShareSheet extends StatefulWidget {
  const QrShareSheet({super.key, required this.item});

  final QrItem item;

  @override
  State<QrShareSheet> createState() => _QrShareSheetState();
}

class _QrShareSheetState extends State<QrShareSheet> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await operation();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('QR action failed: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() => _run(() async {
    final file = await QrImageService.createPng(
      context,
      data: widget.item.data,
      fileName: 'encqder_${widget.item.id}',
    );
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '${widget.item.label}\n${widget.item.data}',
        ),
      );
    } finally {
      if (await file.exists()) await file.delete();
    }
  });

  Future<void> _save() => _run(() async {
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasAccess && !await Gal.requestAccess(toAlbum: true)) {
      throw StateError('Gallery access was not granted.');
    }
    if (!mounted) return;
    final file = await QrImageService.createPng(
      context,
      data: widget.item.data,
      fileName: 'encqder_${widget.item.id}',
    );
    try {
      await Gal.putImage(file.path, album: 'EncQder');
    } finally {
      if (await file.exists()) await file.delete();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to the EncQder gallery album.')),
      );
    }
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Use QR code', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _share,
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share image'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('Save to gallery'),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
