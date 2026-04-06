import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../widgets/atoms/retraq_logo.dart';
import 'home_screen.dart';
import 'recap_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

/// Root navigation shell — manages the four-tab layout.
/// Receives theme toggle callback from RetraqApp.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.onThemeModeChanged,
    required this.themeMode,
  });

  final Future<void> Function(int) onThemeModeChanged;
  final ThemeMode themeMode;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final AnimationController _headerAnim;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Subtle header entrance: fade + slide from left
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _headerFade = CurvedAnimation(
      parent: _headerAnim,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(-0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnim,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldReduce = MediaQuery.of(context).disableAnimations;
    if (shouldReduce != _reduceMotion) {
      _reduceMotion = shouldReduce;
      if (_reduceMotion) {
        // Skip entrance animation — jump to end.
        _headerAnim.value = 1.0;
      } else if (!_headerAnim.isCompleted) {
        _headerAnim.forward();
      }
    } else if (!_reduceMotion && !_headerAnim.isAnimating && !_headerAnim.isCompleted) {
      _headerAnim.forward();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  /// Called by PageView when a swipe or animated transition settles.
  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  /// Called by NavigationBar when a tab is tapped.
  void _onTabSelected(int index) {
    _pageController.animateToPage(
      index,
      duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: SlideTransition(
          position: _headerSlide,
          child: FadeTransition(
            opacity: _headerFade,
            child: Row(
              children: [
                const RetraqLogo(size: 28),
                const SizedBox(width: AppSpacing.sm),
                Semantics(
                  label: 'Retraq',
                  excludeSemantics: true,
                  child: RichText(
                    text: TextSpan(
                      style: tt.headlineSmall?.copyWith(
                        color: cs.primary,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Since',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: 'Then',
                          style: TextStyle(fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: const [],
      ),
      body: RepaintBoundary(
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const HomeScreen(),
            const RecapScreen(),
            const StatsScreen(),
            SettingsScreen(
              onThemeModeChanged: widget.onThemeModeChanged,
              themeMode: widget.themeMode,
            ),
          ],
        ),
      ),
      bottomNavigationBar: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabSelected,
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 80,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.edit_note_outlined),
                  selectedIcon: Icon(Icons.edit_note),
                  label: 'Journal',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome),
                  label: 'Recap',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Stats',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
