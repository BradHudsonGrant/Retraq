import 'package:flutter/material.dart';
import '../../widgets/settings_provider.dart';
import '../../theme/app_spacing.dart';
import '../atoms/bionic_text.dart';

/// Settings row molecule — label + description on left, control widget on right.
/// Reusable for toggles, dropdowns, radio groups in Settings.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg + AppSpacing.xxs),
      // Shared content-card tier used across every tab.
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BionicText(
                  text: title,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                  enabled:
                      SettingsProvider.maybeOf(context)?.bionicReadingEnabled ??
                      false,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  BionicText(
                    text: subtitle!,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    enabled:
                        SettingsProvider.maybeOf(
                          context,
                        )?.bionicReadingEnabled ??
                        false,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          trailing,
        ],
      ),
    );
  }
}
