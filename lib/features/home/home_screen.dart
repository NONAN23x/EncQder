import 'package:flutter/material.dart';

import '../../app/theme_controller.dart';
import '../../data/backup_service.dart';
import '../../data/history_store.dart';
import '../create/create_screen.dart';
import '../history/history_screen.dart';
import '../scan/scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.historyStore,
    required this.backupService,
    required this.themeController,
  });

  final HistoryStore historyStore;
  final BackupService backupService;
  final ThemeController themeController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 1);
  int _selectedIndex = 1;

  void _selectPage(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _selectedIndex = index);
        },
        children: [
          CreateScreen(historyStore: widget.historyStore),
          HistoryScreen(
            historyStore: widget.historyStore,
            backupService: widget.backupService,
            themeController: widget.themeController,
          ),
          ScanScreen(
            active: _selectedIndex == 2,
            onIdle: () => _selectPage(1),
            onSave: (data, kind, origin) async {
              await widget.historyStore.saveItem(
                data,
                kind: kind,
                origin: origin,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved to history.')),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Container(
            key: const ValueKey('home-bottom-navigation'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SizedBox(
              height: 48,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / 3;
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, _) {
                      final currentPage = _pageController.hasClients
                          ? (_pageController.page ?? _selectedIndex.toDouble())
                          : _selectedIndex.toDouble();
                      return Stack(
                        children: [
                          Positioned(
                            left: tabWidth * currentPage,
                            top: 0,
                            bottom: 0,
                            width: tabWidth,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _NavigationItem(
                                  icon: Icons.edit_outlined,
                                  label: 'Create',
                                  index: 0,
                                  currentPage: currentPage,
                                  onTap: _selectPage,
                                ),
                              ),
                              Expanded(
                                child: _NavigationItem(
                                  icon: Icons.history_outlined,
                                  label: 'History',
                                  index: 1,
                                  currentPage: currentPage,
                                  onTap: _selectPage,
                                ),
                              ),
                              Expanded(
                                child: _NavigationItem(
                                  icon: Icons.qr_code_scanner_outlined,
                                  label: 'Scan',
                                  index: 2,
                                  currentPage: currentPage,
                                  onTap: _selectPage,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentPage,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int index;
  final double currentPage;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final selectedAmount = (1 - (currentPage - index).abs()).clamp(0.0, 1.0);
    final colors = Theme.of(context).colorScheme;
    final color = Color.lerp(
      colors.onSurface.withValues(alpha: 0.5),
      colors.primary,
      selectedAmount,
    );

    return Semantics(
      button: true,
      selected: selectedAmount > 0.5,
      label: label,
      child: InkWell(
        key: ValueKey('nav-${label.toLowerCase()}'),
        customBorder: const StadiumBorder(),
        onTap: () => onTap(index),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              Flexible(
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: selectedAmount,
                    child: Opacity(
                      opacity: selectedAmount,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
