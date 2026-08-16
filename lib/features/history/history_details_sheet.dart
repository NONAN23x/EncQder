import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/history_store.dart';
import '../../domain/qr_models.dart';
import '../../domain/qr_payload_codec.dart';
import '../../shared/qr/collapsible_payload_text.dart';
import '../../shared/qr/payload_actions.dart';
import '../../shared/qr/qr_display.dart';
import '../../shared/qr/qr_share_sheet.dart';

Future<void> showHistoryDetails(
  BuildContext context, {
  required QrItem item,
  required HistoryStore historyStore,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        HistoryDetailsSheet(initialItem: item, historyStore: historyStore),
  );
}

class HistoryDetailsSheet extends StatefulWidget {
  const HistoryDetailsSheet({
    super.key,
    required this.initialItem,
    required this.historyStore,
  });

  final QrItem initialItem;
  final HistoryStore historyStore;

  @override
  State<HistoryDetailsSheet> createState() => _HistoryDetailsSheetState();
}

class _HistoryDetailsSheetState extends State<HistoryDetailsSheet> {
  bool _busy = false;

  QrItem get _item {
    for (final item in widget.historyStore.items) {
      if (item.id == widget.initialItem.id) return item;
    }
    return widget.initialItem;
  }

  Future<void> _copy(QrItem item) async {
    await Clipboard.setData(ClipboardData(text: item.data));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('QR content copied.')));
  }

  Future<void> _share(QrItem item) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => QrShareSheet(item: item),
    );
  }

  Future<void> _rename(QrItem item) async {
    final controller = TextEditingController(text: item.label);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename QR code'),
        content: TextField(
          key: const ValueKey('history-label-field'),
          controller: controller,
          autofocus: true,
          maxLength: maximumQrLabelCharacters,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Label',
            hintText: 'QR code',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newLabel == null || !mounted) return;

    await _run(() => widget.historyStore.updateLabel(item.id, newLabel));
  }

  Future<void> _delete(QrItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this QR code?'),
        content: const Text(
          'This removes it from your device. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final deleted = await _run(() => widget.historyStore.removeItem(item.id));
    if (deleted && mounted) Navigator.pop(context);
  }

  Future<void> _hideUpiSuggestion(QrItem item, UpiPayload upi) async {
    final hidden = await _run(
      () => widget.historyStore.forgetUpiId(upi.payeeAddress),
    );
    if (hidden && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${upi.payeeAddress} hidden from suggestions.')),
      );
    }
  }

  Future<bool> _run(Future<void> Function() operation) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await operation();
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update history: $error')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.historyStore,
      builder: (context, _) {
        final item = _item;
        final parsed = QrPayloadCodec.classify(item.data);
        final actionLabel = PayloadActions.labelFor(parsed);
        final colors = Theme.of(context).colorScheme;
        final title = item.label.isEmpty ? 'QR code' : item.label;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Rename',
                    onPressed: _busy ? null : () => _rename(item),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: _busy ? null : () => _delete(item),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: colors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: QrDisplay(
                  data: item.data,
                  size: MediaQuery.sizeOf(context).width.clamp(200, 264),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CollapsiblePayloadText(
                  data: item.data,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _copy(item),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _share(item),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                  ),
                  if (actionLabel != null)
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => PayloadActions.perform(context, parsed),
                      icon: Icon(_actionIcon(parsed)),
                      label: Text(actionLabel),
                    ),
                ],
              ),
              if (parsed.upi case final upi?)
                if (!item.hiddenFromUpiSuggestions) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _hideUpiSuggestion(item, upi),
                    icon: const Icon(Icons.visibility_off_outlined),
                    label: const Text('Hide this UPI ID from suggestions'),
                  ),
                ],
              if (_busy) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        );
      },
    );
  }

  static IconData _actionIcon(ParsedQrPayload payload) {
    if (payload.wifi != null) return Icons.wifi_rounded;
    if (payload.upi != null) return Icons.currency_rupee_rounded;
    return Icons.open_in_new_rounded;
  }
}
