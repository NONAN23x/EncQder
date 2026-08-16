import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../app/theme_controller.dart';
import '../../data/backup_service.dart';
import '../../data/history_store.dart';
import '../../domain/qr_models.dart';
import '../settings/settings_screen.dart';
import 'history_card.dart';
import 'history_details_sheet.dart';

enum HistoryPeriod { all, day, month, year }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.historyStore,
    required this.backupService,
    required this.themeController,
  });

  final HistoryStore historyStore;
  final BackupService backupService;
  final ThemeController themeController;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey _settingsButtonKey = GlobalKey();
  HistoryPeriod _period = HistoryPeriod.all;
  DateTime? _filterDate;
  bool _oldestFirst = false;

  @override
  bool get wantKeepAlive => true;

  List<QrItem> _visibleItems() {
    final items = widget.historyStore.items.where((item) {
      final filterDate = _filterDate;
      if (_period == HistoryPeriod.all || filterDate == null) return true;

      final date = item.createdAt.toLocal();
      return switch (_period) {
        HistoryPeriod.all => true,
        HistoryPeriod.day =>
          date.year == filterDate.year &&
              date.month == filterDate.month &&
              date.day == filterDate.day,
        HistoryPeriod.month =>
          date.year == filterDate.year && date.month == filterDate.month,
        HistoryPeriod.year => date.year == filterDate.year,
      };
    }).toList();

    items.sort(
      (left, right) => _oldestFirst
          ? left.createdAt.compareTo(right.createdAt)
          : right.createdAt.compareTo(left.createdAt),
    );
    return items;
  }

  Future<void> _selectPeriod(HistoryPeriod period) async {
    if (period == HistoryPeriod.all) {
      setState(() {
        _period = HistoryPeriod.all;
        _filterDate = null;
      });
      return;
    }

    final now = DateTime.now();
    final initial = _filterDate ?? now;
    DateTime? selected;
    switch (period) {
      case HistoryPeriod.day:
        selected = await showDatePicker(
          context: context,
          helpText: 'Filter history by day',
          initialDate: initial.isAfter(now) ? now : initial,
          firstDate: DateTime(2000),
          lastDate: now,
        );
      case HistoryPeriod.month:
        selected = await _showMonthPicker(initial);
      case HistoryPeriod.year:
        selected = await _showYearPicker(initial);
      case HistoryPeriod.all:
        return;
    }
    if (selected == null || !mounted) return;
    setState(() {
      _period = period;
      _filterDate = selected;
    });
  }

  Future<DateTime?> _showMonthPicker(DateTime initial) {
    var selectedMonth = initial.month;
    var selectedYear = initial.year;
    final currentYear = DateTime.now().year;
    final localizations = MaterialLocalizations.of(context);

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select month'),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              DropdownButton<int>(
                value: selectedMonth,
                items: [
                  for (var month = 1; month <= 12; month++)
                    DropdownMenuItem(
                      value: month,
                      child: Text(
                        localizations.formatMonthYear(
                          DateTime(selectedYear, month),
                        ),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedMonth = value);
                  }
                },
              ),
              DropdownButton<int>(
                value: selectedYear.clamp(2000, currentYear),
                items: [
                  for (var year = currentYear; year >= 2000; year--)
                    DropdownMenuItem(value: year, child: Text('$year')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedYear = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                DateTime(selectedYear, selectedMonth),
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _showYearPicker(DateTime initial) {
    final now = DateTime.now();
    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select year'),
        content: SizedBox(
          width: 320,
          height: 320,
          child: YearPicker(
            firstDate: DateTime(2000),
            lastDate: now,
            selectedDate: initial,
            onChanged: (date) => Navigator.pop(dialogContext, date),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatFilterDate(BuildContext context) {
    final date = _filterDate;
    if (date == null) return '';
    final localizations = MaterialLocalizations.of(context);
    return switch (_period) {
      HistoryPeriod.day => localizations.formatCompactDate(date),
      HistoryPeriod.month => localizations.formatMonthYear(date),
      HistoryPeriod.year => localizations.formatDecimal(date.year),
      HistoryPeriod.all => '',
    };
  }

  String _formatItemDate(BuildContext context, QrItem item) {
    final date = item.createdAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date));
    return '${localizations.formatCompactDate(date)} · $time';
  }

  void _openSettings() {
    final renderObject = _settingsButtonKey.currentContext?.findRenderObject();
    final box = renderObject is RenderBox ? renderObject : null;
    final origin = box?.localToGlobal(box.size.center(Offset.zero));
    Navigator.push<void>(
      context,
      _SettingsRevealRoute(
        origin: origin,
        builder: (_) => SettingsScreen(
          historyStore: widget.historyStore,
          backupService: widget.backupService,
          themeController: widget.themeController,
        ),
      ),
    );
  }

  void _dismissRecoveryNotice() {
    widget.historyStore.acknowledgeRecoveryNotice();
    widget.historyStore.clearLastError();
  }

  Future<void> _retryHistoryStorage() async {
    try {
      await widget.historyStore.initialize();
      widget.historyStore.clearLastError();
    } catch (_) {
      // HistoryStore records the failure and notifies this screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('EncQder'),
        actions: [
          IconButton(
            key: const ValueKey('open-settings'),
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: KeyedSubtree(
              key: _settingsButtonKey,
              child: const Icon(Icons.settings_rounded),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.historyStore,
        builder: (context, _) {
          final allItems = widget.historyStore.items;
          final visibleItems = _visibleItems();
          final recoveryNotice = widget.historyStore.recoveryNotice;

          return Column(
            children: [
              if (recoveryNotice != null)
                _RecoveryNotice(
                  message: recoveryNotice.message,
                  onDismiss: _dismissRecoveryNotice,
                ),
              if (recoveryNotice == null &&
                  widget.historyStore.lastError != null)
                _StorageErrorNotice(
                  onRetry: widget.historyStore.isInitialized
                      ? null
                      : _retryHistoryStorage,
                  onDismiss: widget.historyStore.clearLastError,
                ),
              if (allItems.isNotEmpty)
                _HistoryControls(
                  period: _period,
                  activeDateLabel: _formatFilterDate(context),
                  oldestFirst: _oldestFirst,
                  onPeriodSelected: _selectPeriod,
                  onClearDate: () => setState(() {
                    _period = HistoryPeriod.all;
                    _filterDate = null;
                  }),
                  onToggleSort: () =>
                      setState(() => _oldestFirst = !_oldestFirst),
                ),
              Expanded(
                child: visibleItems.isEmpty
                    ? _EmptyHistory(
                        filtered: allItems.isNotEmpty,
                        onClearFilter: allItems.isEmpty
                            ? null
                            : () => setState(() {
                                _period = HistoryPeriod.all;
                                _filterDate = null;
                              }),
                      )
                    : ListView.builder(
                        key: const ValueKey('history-list'),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: visibleItems.length,
                        itemBuilder: (context, index) {
                          final item = visibleItems[index];
                          return HistoryCard(
                            key: ValueKey('history-item-${item.id}'),
                            item: item,
                            formattedDate: _formatItemDate(context, item),
                            onTap: () => showHistoryDetails(
                              context,
                              item: item,
                              historyStore: widget.historyStore,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryControls extends StatelessWidget {
  const _HistoryControls({
    required this.period,
    required this.activeDateLabel,
    required this.oldestFirst,
    required this.onPeriodSelected,
    required this.onClearDate,
    required this.onToggleSort,
  });

  final HistoryPeriod period;
  final String activeDateLabel;
  final bool oldestFirst;
  final ValueChanged<HistoryPeriod> onPeriodSelected;
  final VoidCallback onClearDate;
  final VoidCallback onToggleSort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final value in HistoryPeriod.values) ...[
                  ChoiceChip(
                    label: Text(_periodLabel(value)),
                    selected: period == value,
                    onSelected: (_) => onPeriodSelected(value),
                  ),
                  if (value != HistoryPeriod.values.last)
                    const SizedBox(width: 8),
                ],
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: oldestFirst ? 'Oldest first' : 'Newest first',
                  onPressed: onToggleSort,
                  icon: Icon(
                    oldestFirst
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                  ),
                ),
              ],
            ),
          ),
          if (period != HistoryPeriod.all && activeDateLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            InputChip(
              label: Text(activeDateLabel),
              onDeleted: onClearDate,
              deleteButtonTooltipMessage: 'Clear date filter',
            ),
          ],
        ],
      ),
    );
  }

  static String _periodLabel(HistoryPeriod period) => switch (period) {
    HistoryPeriod.all => 'All',
    HistoryPeriod.day => 'Day',
    HistoryPeriod.month => 'Month',
    HistoryPeriod.year => 'Year',
  };
}

class _RecoveryNotice extends StatelessWidget {
  const _RecoveryNotice({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              color: colors.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onTertiaryContainer),
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded),
              color: colors.onTertiaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageErrorNotice extends StatelessWidget {
  const _StorageErrorNotice({required this.onRetry, required this.onDismiss});

  final Future<void> Function()? onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: colors.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'History storage is unavailable. Recent changes may not '
                    'have been saved.',
                    style: TextStyle(color: colors.onErrorContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (onRetry != null)
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.filtered, required this.onClearFilter});

  final bool filtered;
  final VoidCallback? onClearFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 360;
        final illustrationSize = compact ? 88.0 : 128.0;
        final illustration = Container(
          width: illustrationSize,
          height: illustrationSize,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            filtered ? Icons.filter_alt_off_rounded : Icons.qr_code_2_rounded,
            size: illustrationSize / 2,
            color: colors.onPrimaryContainer,
          ),
        );
        final copy = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filtered ? 'No matching QR codes' : 'Your history is empty',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              filtered
                  ? 'Choose another date or clear the filter.'
                  : 'Create or scan a QR code, then save it to see it here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (onClearFilter != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: onClearFilter,
                child: const Text('Clear filter'),
              ),
            ],
          ],
        );
        return SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 20 : 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(
                0,
                constraints.maxHeight - (compact ? 40 : 64),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: compact
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          illustration,
                          const SizedBox(width: 28),
                          Flexible(child: copy),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          illustration,
                          const SizedBox(height: 24),
                          copy,
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _SettingsRevealRoute<T> extends PageRouteBuilder<T> {
  _SettingsRevealRoute({required this.builder, required this.origin})
    : super(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionDuration: const Duration(seconds: 1),
        reverseTransitionDuration: const Duration(seconds: 1),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final mediaQuery = MediaQuery.of(context);
          if (mediaQuery.disableAnimations) return child;
          final size = MediaQuery.sizeOf(context);
          final center = origin ?? Offset(size.width / 2, size.height / 2);
          final radius = _revealRadius(size, center);
          return AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              final curve = animation.status == AnimationStatus.reverse
                  ? Curves.easeInCubic
                  : Curves.easeOutCubic;
              final progress = curve.transform(animation.value);
              return ClipPath(
                clipper: _CircleRevealClipper(
                  center: center,
                  radius: radius * progress,
                ),
                child: child,
              );
            },
          );
        },
      );

  final WidgetBuilder builder;
  final Offset? origin;

  static double _revealRadius(Size size, Offset center) {
    final corners = <Offset>[
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    return corners.map((corner) => (corner - center).distance).reduce(math.max);
  }
}

final class _CircleRevealClipper extends CustomClipper<Path> {
  const _CircleRevealClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_CircleRevealClipper oldClipper) =>
      oldClipper.center != center || oldClipper.radius != radius;
}
