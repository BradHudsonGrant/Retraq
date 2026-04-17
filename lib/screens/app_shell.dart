import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_motion.dart';
import '../utils/test_keys.dart';
import '../widgets/atoms/morph_icon.dart';
import '../widgets/atoms/tab_swipe_edge_glow.dart';
import 'active_tab_scope.dart';
import 'home_screen.dart';
import 'recap_screen.dart';
import 'settings_screen.dart';

/// Root navigation shell — manages the three-tab layout.
///
/// Task 2.5 — Stats was previously a top-level tab; now collapsed
/// into Recap via the Entries/Insights pill. The embedded
/// StatsScreen(embedded: true) renders inside RecapScreen when the
/// user taps Insights. This bottom nav carries Jot / Recap /
/// Settings only.
///
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

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Called by PageView when a swipe or animated transition settles.
  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  /// Called by NavigationBar when a tab is tapped.
  void _onTabSelected(int index) {
    final reduceMotion = AppMotion.reduce(context);
    _pageController.animateToPage(
      index,
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 360),
      curve: AppMotion.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = L10n.of(context)!;

    return Scaffold(
      // No top AppBar — each screen owns its own header for max real-estate
      // and a faster, less repaint-heavy shell.
      //
      // Task 2.12 — TabSwipeEdgeGlow wraps the PageView so accidental
      // horizontal drags (which the NeverScrollableScrollPhysics below
      // would silently swallow) now pulse a brief teal edge glow.
      // Signals "we heard you, use the tabs" instead of looking frozen.
      // Respects reduce-motion — no glow in that case.
      //
      // Task 8.6 — `ActiveTabScope` exposes the current `_currentIndex`
      // to descendants so tabs can pause stream subscriptions when
      // they're inactive. HomeScreen reads this in
      // `didChangeDependencies` and pauses its 4 Drift watcher subs
      // when the user is on Recap or Settings.
      body: ActiveTabScope(
        activeIndex: _currentIndex,
        child: TabSwipeEdgeGlow(
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              const HomeScreen(),
              const RecapScreen(),
              SettingsScreen(
                onThemeModeChanged: widget.onThemeModeChanged,
                themeMode: widget.themeMode,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              top: BorderSide(
                // WCAG 1.4.11: full-opacity outlineVariant so the nav bar
                // boundary stays visible. The 0.3-alpha overlay used to crush
                // effective contrast against dark surface to ~1.4:1.
                color: cs.outlineVariant,
                width: 0.5,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabSelected,
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 80,
              destinations: [
                NavigationDestination(
                  key: TestKeys.navJournalTab,
                  icon: MorphIcon(
                    icon: Icons.edit_outlined,
                    selectedIcon: Icons.edit,
                    selected: _currentIndex == 0,
                  ),
                  selectedIcon: const Icon(Icons.edit),
                  label: l10n.navJot,
                ),
                NavigationDestination(
                  key: TestKeys.navRecapTab,
                  icon: MorphIcon(
                    icon: Icons.auto_awesome_outlined,
                    selectedIcon: Icons.auto_awesome,
                    selected: _currentIndex == 1,
                  ),
                  selectedIcon: const Icon(Icons.auto_awesome),
                  label: l10n.navRecap,
                ),
                NavigationDestination(
                  key: TestKeys.navSettingsTab,
                  icon: MorphIcon(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    selected: _currentIndex == 2,
                  ),
                  selectedIcon: const Icon(Icons.settings),
                  label: l10n.navSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
