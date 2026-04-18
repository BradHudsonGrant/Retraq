import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:retraq/l10n/app_localizations.dart';

import '../models/journal_entry.dart';
import '../widgets/settings_provider.dart';
import '../services/database_service.dart';
import '../services/stats_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../widgets/atoms/app_snack_bar.dart';
import '../widgets/atoms/bionic_text.dart';
import '../widgets/atoms/glow_box.dart';
import '../widgets/atoms/mood_blob.dart';
import '../utils/adaptive_layout.dart';
import '../widgets/molecules/mood_selector.dart';
import '../widgets/molecules/stat_card.dart';
import '../widgets/molecules/weekly_trend_chart.dart';

/// Stats screen — journaling statistics and trends.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, this.embedded = false});

  /// Task 2.5 — when true, skip the Stats-specific outer chrome
  /// (top gradient, header row, page padding, nav-bar clearance) so
  /// this widget can live INSIDE the RecapScreen "Insights" pane
  /// without visually fighting Recap's own header + scroll. Callers
  /// on AppShell leave this false (default) to get the full
  /// standalone page.
  final bool embedded;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final StatsService _statsSvc = DatabaseService.instance.stats;

  StatsSnapshot _stats = const StatsSnapshot();
  StreamSubscription<StatsSnapshot>? _statsSub;
  bool _isLoading = true;

  /// Entry from exactly one year ago today, if any.
  JournalEntry? _onThisDayEntry;

  static List<String> _dayNames(L10n l10n) => [
    l10n.mondayName,
    l10n.tuesdayName,
    l10n.wednesdayName,
    l10n.thursdayName,
    l10n.fridayName,
    l10n.saturdayName,
    l10n.sundayName,
  ];

  @override
  void initState() {
    super.initState();
    _statsSub = _statsSvc.watchAllStats(weeks: 12).listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _stats = snapshot;
        _isLoading = false;
      });
    });
    _loadOnThisDay();
  }

  void _onWeekTapped(BuildContext context, int index) {
    final data = _stats.weeklyTrends;
    if (index < 0 || index >= data.length) return;

    final now = DateTime.now();
    final int weeksAgo = data.length - 1 - index;
    // Monday of that week.
    final weekStart = now.subtract(
      Duration(days: weeksAgo * 7 + now.weekday - 1),
    );
    final weekEnd = weekStart.add(const Duration(days: 6));
    final fmt = DateFormat.MMMd();
    final range = '${fmt.format(weekStart)} – ${fmt.format(weekEnd)}';
    final count = data[index];

    // Task 2.3 — localized ICU plural ("no entries" / "1 entry" /
    // "{count} entries") via weekEntryCountSnackbar ARB key.
    final l10n = L10n.of(context)!;
    AppSnackBar.show(
      context,
      l10n.weekEntryCountSnackbar(range, count),
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _loadOnThisDay() async {
    // Task 1.3 — delegate to StatsService.onThisDayEntries so leap-day
    // semantics and error handling stay in one place + the rule is
    // directly unit-testable without booting the whole screen.
    final entries = await _statsSvc.onThisDayEntries();
    if (!mounted) return;
    if (entries.isNotEmpty) {
      setState(() => _onThisDayEntry = entries.first);
    }
  }

  @override
  void dispose() {
    _statsSub?.cancel();
    super.dispose();
  }

  Widget _buildLoadingSkeleton(ColorScheme cs) {
    return _SkeletonShimmer(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _skeletonCard(cs)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _skeletonCard(cs)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _skeletonCard(cs)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _skeletonCard(cs)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: AppSpacing.borderRadiusXl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonCard(ColorScheme cs) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusXl,
      ),
    );
  }

  Widget _buildOnThisDayCard(ColorScheme cs, TextTheme tt) {
    final entry = _onThisDayEntry;
    if (entry == null) return const SizedBox.shrink();
    final l10n = L10n.of(context)!;

    final text = entry.displayText;
    final preview = text.length > 150 ? '${text.substring(0, 150)}...' : text;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: GlowBox(
        color: cs.tertiary,
        glowOpacity: 0.42,
        blurRadius: 30,
        spreadRadius: 2,
        borderRadius: AppSpacing.borderRadiusXl,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: cs.tertiaryContainer,
            borderRadius: AppSpacing.borderRadiusXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: cs.onTertiaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.onThisDayLastYear,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (entry.mood != null) ...[
                MoodBlob(
                  mood: entry.mood!,
                  size: 32,
                  color: moodColorFor(
                    entry.mood!,
                    Theme.of(context).brightness,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (preview.isNotEmpty)
                BionicText(
                  text: preview,
                  style: tt.bodyMedium?.copyWith(color: cs.onTertiaryContainer),
                  enabled:
                      SettingsProvider.maybeOf(context)?.bionicReadingEnabled ??
                      false,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStats() {
    final l10n = L10n.of(context)!;
    return Semantics(
      container: true,
      // Task 2.11 — localized screen-reader label.
      label: l10n.statisticsOverview,
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: l10n.totalEntries,
              value: _stats.totalEntries,
              icon: Icons.edit_note,
              delay: 0,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatCard(
              label: l10n.daysJournaled,
              value: _stats.totalDays,
              icon: Icons.calendar_today,
              delay: 100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreaksSection(ColorScheme cs, TextTheme tt) {
    final l10n = L10n.of(context)!;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
        leading: Icon(Icons.local_fire_department, color: cs.onSurfaceVariant),
        title: Text(
          l10n.streaksSection,
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: l10n.currentStreak,
                  value: _stats.currentStreak,
                  icon: Icons.local_fire_department,
                  suffix: l10n.daysSuffix,
                  delay: 0,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  label: l10n.bestStreak,
                  value: _stats.longestStreak,
                  icon: Icons.emoji_events,
                  suffix: l10n.daysSuffix,
                  delay: 100,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Streak freeze card (1 free miss per 7 days) was removed: the
          // allowance was invisible to users until it had already been
          // spent, which made streaks feel arbitrary. A single bottom-
          // spanning StatCard reads cleaner than the old two-column row
          // with an asymmetric freeze tile on the right.
          StatCard(
            label: l10n.longestThisMonth,
            value: _stats.longestStreakThisMonth,
            icon: Icons.date_range,
            suffix: l10n.daysSuffix,
            delay: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildMostActiveDay(ColorScheme cs, TextTheme tt) {
    if (_stats.mostActiveWeekday < 1 || _stats.mostActiveWeekday > 7) {
      return const SizedBox.shrink();
    }
    final l10n = L10n.of(context)!;
    final dayName = _dayNames(l10n)[_stats.mostActiveWeekday - 1];
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.insights, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          BionicText(
            text: l10n.mostActiveDay(dayName),
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            enabled:
                SettingsProvider.maybeOf(context)?.bionicReadingEnabled ??
                false,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection(ColorScheme cs, TextTheme tt) {
    if (_stats.averageMood == null || _stats.moodDistribution.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = L10n.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.moodTitle,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: AppSpacing.borderRadiusXl,
          ),
          child: Row(
            children: [
              MoodBlob(
                mood: _stats.averageMood!.round(),
                size: 40,
                color: moodColorFor(
                  _stats.averageMood!.round(),
                  Theme.of(context).brightness,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.moodAverage(_stats.averageMood!.toStringAsFixed(1)),
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    moodLabel(_stats.averageMood!.round()),
                    style: tt.bodyMedium?.copyWith(
                      color: moodColor(_stats.averageMood!.round()),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildMoodDistribution(cs, tt),
      ],
    );
  }

  Widget _buildPhoneStats(ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroStats(),
        const SizedBox(height: AppSpacing.lg),
        if (_stats.weeklyTrends.isNotEmpty)
          WeeklyTrendChart(
            data: _stats.weeklyTrends,
            onWeekTapped: (i) => _onWeekTapped(context, i),
          ),
        _buildMostActiveDay(cs, tt),
        _buildMoodSection(cs, tt),
        const SizedBox(height: AppSpacing.md),
        _buildStreaksSection(cs, tt),
      ],
    );
  }

  Widget _buildTabletStats(ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveTwoPane(
          leftFraction: 0.4,
          left: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroStats(),
              _buildMostActiveDay(cs, tt),
              _buildMoodSection(cs, tt),
            ],
          ),
          right: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_stats.weeklyTrends.isNotEmpty)
                  WeeklyTrendChart(
                    data: _stats.weeklyTrends,
                    onWeekTapped: (i) => _onWeekTapped(context, i),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildStreaksSection(cs, tt),
      ],
    );
  }

  Widget _buildMoodDistribution(ColorScheme cs, TextTheme tt) {
    final dist = _stats.moodDistribution;
    final maxCount = dist.values.fold<int>(0, (a, b) => a > b ? a : b);
    if (maxCount == 0) return const SizedBox.shrink();
    final l10n = L10n.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.moodDistribution,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (int mood = 5; mood >= 1; mood--)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Center(
                      child: MoodBlob(
                        mood: mood,
                        size: 20,
                        color: moodColorFor(mood, Theme.of(context).brightness),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppSpacing.borderRadiusSm,
                      child: LinearProgressIndicator(
                        value: (dist[mood] ?? 0) / maxCount,
                        backgroundColor: cs.surfaceContainerHigh,
                        color: moodColor(mood),
                        minHeight: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${dist[mood] ?? 0}',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    // Task 2.5 — when embedded inside RecapScreen's Insights pane,
    // the outer chrome (gradient, SafeArea, page padding, Stats
    // header, nav-bar bottom padding) all come from the enclosing
    // Recap screen. Render just the stats Column directly.
    if (widget.embedded) {
      return _buildStatsColumn(cs, tt, l10n, embedded: true);
    }

    // Gradient sits OUTSIDE SafeArea so it paints behind the status bar,
    // flowing the system chrome into the Stats header. Only the scroll
    // view respects the safe-area insets.
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 300,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cs.primary.withValues(alpha: 0.18),
                    cs.surface.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),

                // ── Header ──
                Animate(
                  effects: [
                    FadeEffect(duration: 500.ms, curve: Curves.easeOut),
                    SlideEffect(
                      begin: const Offset(-0.04, 0),
                      end: Offset.zero,
                      duration: 550.ms,
                      curve: AppMotion.emphasizedDecelerate,
                    ),
                  ],
                  // Brand mark removed; the Stats title anchors the
                  // header on its own, matching the other tabs.
                  child: Text(
                    l10n.statsTitle,
                    style: tt.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                BionicText(
                  text: l10n.statsSubtitle,
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  enabled:
                      SettingsProvider.maybeOf(context)?.bionicReadingEnabled ??
                      false,
                ),

                const SizedBox(height: AppSpacing.lg),

                _buildStatsColumn(cs, tt, l10n, embedded: false),
                // ── Bottom padding for nav bar ──
                const SizedBox(height: AppSpacing.navBarClearance),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Stats content column — extracted from the build tree so it can
  /// render either inside StatsScreen's own chrome (embedded=false)
  /// or inside RecapScreen's Insights pane (embedded=true).
  Widget _buildStatsColumn(
    ColorScheme cs,
    TextTheme tt,
    L10n l10n, {
    required bool embedded,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Loading skeleton ──
        if (_isLoading)
          _buildLoadingSkeleton(cs)
        // ── Empty state ──
        else if (_stats.totalEntries == 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.noStatsYet,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  BionicText(
                    text: l10n.noStatsYetMessage,
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color:
                          cs.onSurfaceVariant.withValues(alpha: 0.75),
                    ),
                    enabled: SettingsProvider.maybeOf(context)
                            ?.bionicReadingEnabled ??
                        false,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          _buildOnThisDayCard(cs, tt),
          if (isTablet(context))
            _buildTabletStats(cs, tt)
          else
            _buildPhoneStats(cs, tt),
        ],
      ],
    );
  }
}

/// Pulsing opacity animation for loading skeleton placeholders.
class _SkeletonShimmer extends StatefulWidget {
  const _SkeletonShimmer({required this.child});
  final Widget child;

  @override
  State<_SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<_SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // WCAG 2.3.3 — honour the OS reduce-motion setting. When motion is
    // disabled we hold the controller at midpoint (steady 50% opacity)
    // instead of repeating the pulse, matching the lock-screen logo.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder:
          (context, child) =>
              Opacity(opacity: 0.3 + 0.4 * _controller.value, child: child),
      child: widget.child,
    );
  }
}
