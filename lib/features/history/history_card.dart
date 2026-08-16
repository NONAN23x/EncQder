import 'package:flutter/material.dart';

import '../../domain/qr_models.dart';

class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
    required this.item,
    required this.formattedDate,
    required this.onTap,
  });

  final QrItem item;
  final String formattedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = item.label.isEmpty ? _fallbackLabel(item.kind) : item.label;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: '$label, ${_kindLabel(item.kind)}, $formattedDate',
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    _kindIcon(item.kind),
                    color: colors.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.data,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _MetadataChip(label: _originLabel(item.origin)),
                          _MetadataChip(label: _kindLabel(item.kind)),
                          Text(
                            formattedDate,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _kindIcon(QrKind kind) => switch (kind) {
    QrKind.text => Icons.text_fields_rounded,
    QrKind.wifi => Icons.wifi_rounded,
    QrKind.upi => Icons.currency_rupee_rounded,
  };

  static String _kindLabel(QrKind kind) => switch (kind) {
    QrKind.text => 'Text',
    QrKind.wifi => 'Wi-Fi',
    QrKind.upi => 'UPI',
  };

  static String _originLabel(QrOrigin origin) => switch (origin) {
    QrOrigin.generated => 'Created',
    QrOrigin.scanned => 'Scanned',
    QrOrigin.imported => 'Imported',
  };

  static String _fallbackLabel(QrKind kind) => switch (kind) {
    QrKind.text => 'QR code',
    QrKind.wifi => 'Wi-Fi code',
    QrKind.upi => 'UPI code',
  };
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
