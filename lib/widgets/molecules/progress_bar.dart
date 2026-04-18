import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../atoms/bionic_text.dart';

/// Weekly-progress pill shown on the Home hero area.
///
/// Task 1.2 — extracted from `home_screen.dart::_buildProgressBar` so
/// the screen shrinks toward its 400-LOC target and the widget becomes
/// independently testable. Zero business logic: renders whatever the
/// parent passes in.
///
/// States (driven by [weekCount]):
///   - null  → blank (loading, avoids flash before the first stream
///             emission lands)
///   - 0     → "Drop your first traq above." with edit-note icon
///   - 1..n  → "{n} traqs this week — keep going!" with flame icon
///
/// [bionicReadingEnabled] threads through the same accessibility
/// preference the rest of the home screen honours.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.weekCount,
    this.bionicReadingEnabled = false,
  });

  final int? weekCount;
  final bool bionicReadingEnabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;
    final hasStreak = (weekCount ?? 0) > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      // Shared "minimal-border card" treatment — matches RecentDayCard
      // and the Recap day cards so every card in the shell reads with
      // the same surface language. The 1px outline at 0.35 alpha is
      // what actually carries the contrast against the ambient
      // gradient; the fill itself stays understated.
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasStreak ? Icons.local_fire_department : Icons.edit_note,
            size: 18,
            // Task 13.3 — warm amber flame when the streak is active
            // (2nd sanctioned accent-amber usage alongside the
            // milestone chip in SaveSuccessOverlay). The edit-note
            // placeholder stays in the primary green so the icon's
            // color itself signals "momentum present" vs "get started".
            color: hasStreak
                ? AppColors.accentAmber(Theme.of(context).brightness)
                : cs.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: BionicText(
              text: weekCount == null
                  ? '' // Loading — avoid flash
                  : weekCount == 0
                      ? l10n.progressFirstEntry
                      : l10n.progressWeekCount(weekCount!),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              enabled: bionicReadingEnabled,
            ),
          ),
        ],
      ),
    );
  }
}
