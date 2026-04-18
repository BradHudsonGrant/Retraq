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
/// Renders only when [weekCount] is `>= 1` — while the week is blank the
/// pill collapses to `SizedBox.shrink()` rather than showing an empty
/// placeholder card that reads as dead space above the composer.
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

    // Hide the pill entirely when no traqs exist this week — otherwise it
    // renders as an empty/placeholder card that draws the eye without
    // earning it. The hero message above already nudges first-timers.
    if (!hasStreak) {
      return const SizedBox.shrink();
    }

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
            Icons.local_fire_department,
            size: 18,
            // Task 13.3 — warm amber flame, the 2nd sanctioned accent-amber
            // usage alongside the milestone chip in SaveSuccessOverlay.
            color: AppColors.accentAmber(Theme.of(context).brightness),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: BionicText(
              text: l10n.progressWeekCount(weekCount!),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              enabled: bionicReadingEnabled,
            ),
          ),
        ],
      ),
    );
  }
}
