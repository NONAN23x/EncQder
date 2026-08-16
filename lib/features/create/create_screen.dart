import 'package:flutter/material.dart';

import '../../data/history_store.dart';
import '../../domain/qr_models.dart';
import '../../shared/qr/collapsible_payload_text.dart';
import '../../shared/qr/qr_display.dart';
import '../../shared/qr/qr_share_sheet.dart';
import '../../shared/qr/qr_style.dart';
import 'create_forms.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key, required this.historyStore});

  final HistoryStore historyStore;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen>
    with AutomaticKeepAliveClientMixin {
  int? _openSection;

  @override
  bool get wantKeepAlive => true;

  Future<void> _showPreview(String data, QrKind kind) async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      QrStyle.encode(data);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This payload is too large to encode as a QR code.'),
        ),
      );
      return;
    }
    final preview = QrItem(
      id: 'preview-${data.hashCode}',
      data: data,
      createdAt: DateTime.now(),
      kind: kind,
      label: 'Preview',
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _PreviewSheet(
        item: preview,
        onSave: () async {
          await widget.historyStore.saveItem(data, kind: kind);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saved to Home!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create QR')),
      body: AnimatedBuilder(
        animation: widget.historyStore,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    _CreateSection(
                      title: 'Text / URL',
                      icon: Icons.text_fields_rounded,
                      expanded: _openSection == 0,
                      onTap: () => setState(
                        () => _openSection = _openSection == 0 ? null : 0,
                      ),
                      child: TextQrForm(onPreview: _showPreview),
                    ),
                    _CreateSection(
                      title: 'Wi-Fi Network',
                      icon: Icons.wifi_rounded,
                      expanded: _openSection == 1,
                      onTap: () => setState(
                        () => _openSection = _openSection == 1 ? null : 1,
                      ),
                      child: WifiQrForm(onPreview: _showPreview),
                    ),
                    _CreateSection(
                      title: 'UPI Payment',
                      icon: Icons.account_balance_wallet_rounded,
                      expanded: _openSection == 2,
                      onTap: () => setState(
                        () => _openSection = _openSection == 2 ? null : 2,
                      ),
                      child: UpiQrForm(
                        suggestions: widget.historyStore.getRecentUpiIds(),
                        onForgetSuggestion: (vpa) async {
                          await widget.historyStore.forgetUpiId(vpa);
                          if (mounted) setState(() {});
                        },
                        onPreview: _showPreview,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CreateSection extends StatelessWidget {
  const _CreateSection({
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(
        bottom: expanded ? 24 : 12,
        top: expanded ? 12 : 0,
      ),
      decoration: BoxDecoration(
        color: expanded
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(expanded ? 24 : 16),
        border: Border.all(
          color: expanded
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: expanded ? 2 : 1,
        ),
        boxShadow: expanded
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : const [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(expanded ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              expanded: expanded,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: expanded
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            size: 20,
                            color: expanded
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: expanded
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: expanded
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: expanded
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: child,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewSheet extends StatefulWidget {
  const _PreviewSheet({required this.item, required this.onSave});

  final QrItem item;
  final Future<void> Function() onSave;

  @override
  State<_PreviewSheet> createState() => _PreviewSheetState();
}

class _PreviewSheetState extends State<_PreviewSheet> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save QR code: $error')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Preview',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Center(child: QrDisplay(data: widget.item.data, size: 260)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CollapsiblePayloadText(data: widget.item.data),
            ),
            const SizedBox(height: 20),
            OverflowBar(
              alignment: MainAxisAlignment.center,
              overflowAlignment: OverflowBarAlignment.center,
              spacing: 12,
              overflowSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (_) => QrShareSheet(item: widget.item),
                  ),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Use'),
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
