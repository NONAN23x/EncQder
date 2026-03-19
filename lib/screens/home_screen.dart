import 'package:flutter/material.dart';

import '../services/theme_provider.dart';
import 'input_screen.dart';
import 'history_screen.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const HomeScreen({super.key, required this.themeProvider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(
    initialPage: 1,
  ); // Start on History

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        children: [
          const InputScreen(),
          HistoryScreen(themeProvider: widget.themeProvider),
          CameraScreen(pageController: _pageController),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color:
                    Theme.of(context).cardTheme.shape is RoundedRectangleBorder
                    ? (Theme.of(context).cardTheme.shape
                              as RoundedRectangleBorder)
                          .side
                          .color
                    : Colors.transparent,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double tabWidth = constraints.maxWidth / 3;
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double currentPage = _pageController.hasClients ? (_pageController.page ?? 1.0) : 1.0;
                    return Stack(
                      children: [
                        Positioned(
                          left: tabWidth * currentPage,
                          top: 0,
                          bottom: 0,
                          width: tabWidth,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: _buildNavItem(context, Icons.edit_outlined, 0, 'Create')),
                            Expanded(child: _buildNavItem(context, Icons.history, 1, 'Home')),
                            Expanded(child: _buildNavItem(context, Icons.qr_code_scanner, 2, 'Scan')),
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
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    int index,
    String label,
  ) {
    // The parent Row is now inside an AnimatedBuilder, so we don't strictly need one here,
    // but we can just compute currentPage directly.
    double currentPage = _pageController.hasClients
        ? (_pageController.page ?? 1.0)
        : 1.0;
    final double t = (1.0 - (currentPage - index).abs()).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _navigateToPage(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.transparent, // Ensure full hit area
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Color.lerp(
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                Theme.of(context).colorScheme.primary,
                t,
              ),
            ),
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: t,
                heightFactor: 1.0,
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: Color.lerp(
                            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            Theme.of(context).colorScheme.primary,
                            t,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
