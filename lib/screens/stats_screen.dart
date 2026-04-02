import 'dart:async';
import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../services/stats_service.dart';
import '../theme/app_spacing.dart';
import '../utils/adaptive_layout.dart';
import '../widgets/molecules/mood_selector.dart';
import '../widgets/molecules/stat_card.dart';
import '../widgets/molecules/weekly_trend_chart.dart';

/// Stats screen — journaling statistics and trends.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

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

  static const _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _statsSub = _statsSvc.watchAllStats(weeks: 12).listen((snapshot) {
      if (!mounted) return;
      setState(() => _stats = snapshot);
    });
  }

  @override
  void dispose() {
    _statsSub?.cancel();
    super.dispose();
  }

  Widget _buildHeroStats() {
    return Semantics(
      container: true,
      label: 'Statistics overview',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total Entries',
                  value: _stats.totalEntries,
                  icon: Icons.edit_note,
                  delay: 0,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  label: 'Days Journaled',
                  value: _stats.totalDays,
                  icon: Icons.calendar_today,
                  delay: 100,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Current Streak',
                  value: _stats.currentStreak,
                  icon: Icons.local_fire_department,
                  suffix: 'days',
                  delay: 200,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  label: 'Best Streak',
                  value: _stats.longestStreak,
                  icon: Icons.emoji_events,
                  suffix: 'days',
                  delay: 300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMostActiveDay(ColorScheme cs, TextTheme tt) {
    if (_stats.mostActiveWeekday < 1 || _stats.mostActiveWeekday > 7) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.insights, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Most active day: ${_dayNames[_stats.mostActiveWeekday - 1]}',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection(ColorScheme cs, TextTheme tt) {
    if (_stats.averageMood == null || _stats.moodDistribution.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Mood',
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
              Text(
                moodEmoji(_stats.averageMood!.round()),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Average: ${_stats.averageMood!.toStringAsFixed(1)}',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
          WeeklyTrendChart(data: _stats.weeklyTrends),
        _buildMostActiveDay(cs, tt),
        _buildMoodSection(cs, tt),
      ],
    );
  }

  Widget _buildTabletStats(ColorScheme cs, TextTheme tt) {
    return AdaptiveTwoPane(
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
              WeeklyTrendChart(data: _stats.weeklyTrends),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodDistribution(ColorScheme cs, TextTheme tt) {
    final dist = _stats.moodDistribution;
    final maxCount = dist.values.fold<int>(0, (a, b) => a > b ? a : b);
    if (maxCount == 0) return const SizedBox.shrink();

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
            'Distribution',
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
                    child: Text(
                      moodEmoji(mood),
                      style: const TextStyle(fontSize: 16),
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // ── Header ──
            Text(
              'Stats',
              style: tt.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Your journey so far.',
              style: tt.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Empty state ──
            if (_stats.totalEntries == 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xxl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 48,
                        color: cs.onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No stats yet',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Start journaling to see your patterns and streaks.',
                        textAlign: TextAlign.center,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_stats.totalEntries > 0) ...[
              if (isTablet(context))
                _buildTabletStats(cs, tt)
              else
                _buildPhoneStats(cs, tt),
            ], // end if totalEntries > 0

            // ── Bottom padding for nav bar ──
            const SizedBox(height: AppSpacing.navBarClearance),
          ],
        ),
      ),
    );
  }
}
