import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../atoms/bionic_text.dart';

/// Compact weekly-streak pill shown inline with the "Recent" header.
///
/// Previously a full-width RetraqCard that read as just another entry
/// card stacked between the composer and the Recent section. Slimmed
/// down to a rounded-full pill (flame + count) so it sits as a status
/// badge next to the Recent label instead of eating vertical space on
/// its own row.
///
/// Renders only when [weekCount] is `>= 1` — on a blank week it
/// collapses to `SizedBox.shrink()` so the Recent header row reads
/// cleanly without a lonely "0" badge.
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

    if (!hasStreak) {
      return const SizedBox.shrink();
    }

    // Amber is the "celebratory / streak" accent per app_colors.dart
    // guidelines. Low-alpha fill (~0.12) keeps the pill warm without
    // shouting; full-strength amber on the icon carries the signal.
    final amber = AppColors.accentAmber(Theme.of(context).brightness);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.12),
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 14, color: amber),
          const SizedBox(width: AppSpacing.xxs),
          BionicText(
            text: l10n.progressWeekCount(weekCount!),
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            enabled: bionicReadingEnabled,
          ),
        ],
      ),
    );
  }
}
