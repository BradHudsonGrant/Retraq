import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/settings_provider.dart';
import '../../theme/app_spacing.dart';
import '../atoms/bionic_text.dart';
import '../atoms/glow_box.dart';

class NudgeCard extends StatelessWidget {
  const NudgeCard({
    super.key,
    required this.nudgeHour,
    this.nudgeMinute = 0,
    required this.onChangeTime,
  });

  final int nudgeHour;
  final int nudgeMinute;
  final VoidCallback onChangeTime;

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    return GlowBox(
      color: cs.primary,
      glowOpacity: 0.42,
      blurRadius: 30,
      spreadRadius: 1,
      borderRadius: AppSpacing.borderRadiusXxl,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: AppSpacing.borderRadiusXxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.notifications_active,
                size: 36,
                color: cs.onPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            BionicText(
              // Task 2.14 — body copy localized.
              text: l10n.nudgeCardBody,
              style: tt.titleMedium?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              enabled:
                  SettingsProvider.maybeOf(context)?.bionicReadingEnabled ??
                  false,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  // Task 7.9 — localize "Daily at {time}". The
                  // pre-formatted time string keeps locale-specific
                  // time formatting from _formatTime.
                  l10n.dailyAtTime(_formatTime(nudgeHour, nudgeMinute)),
                  style: tt.bodySmall?.copyWith(color: cs.onPrimary),
                ),
                GlowBox(
                  color: cs.surfaceContainerLowest,
                  glowOpacity: 0.55,
                  blurRadius: 18,
                  borderRadius: AppSpacing.borderRadiusFull,
                  child: FilledButton(
                    onPressed: onChangeTime,
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.surfaceContainerLowest,
                      foregroundColor: cs.primary,
                    ),
                    // Task 2.14 — Change Time button label localized.
                    child: Text(l10n.nudgeChangeTime),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Task 2.14 — surface the skip-if-journaled behavior so users
            // know the reminder won't fire after they've already written
            // something for the day. This fixes the "won't it just nag
            // me if I already journaled?" perception that was causing
            // users to disable nudges wholesale.
            Text(
              l10n.nudgeSkipIfJournaledHint,
              style: tt.bodySmall?.copyWith(
                color: cs.onPrimary.withValues(alpha: 0.85),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
