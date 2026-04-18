import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/settings_provider.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/atoms/bionic_text.dart';
import '../../widgets/organisms/theme_card.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final Future<void> Function(int) onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.appearanceTitle, style: tt.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        BionicText(
          text: l10n.appearanceSubtitle,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          enabled:
              SettingsProvider.maybeOf(context)?.bionicReadingEnabled ?? false,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: ThemeCard(
                label: l10n.themeSystem,
                isSelected: themeMode == ThemeMode.system,
                isDark: null,
                onTap: () => onThemeModeChanged(0),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ThemeCard(
                label: l10n.themeDay,
                isSelected: themeMode == ThemeMode.light,
                isDark: false,
                onTap: () => onThemeModeChanged(1),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ThemeCard(
                label: l10n.themeNight,
                isSelected: themeMode == ThemeMode.dark,
                isDark: true,
                onTap: () => onThemeModeChanged(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
