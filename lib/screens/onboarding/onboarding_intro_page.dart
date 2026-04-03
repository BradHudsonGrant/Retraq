import 'package:flutter/material.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/atoms/bionic_text.dart';
import 'onboarding_page_data.dart';

/// A single intro/feature page shown during onboarding.
class OnboardingIntroPage extends StatelessWidget {
  const OnboardingIntroPage({super.key, required this.data});

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 48, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: AppSpacing.xl),
          BionicText(
            text: data.title,
            textAlign: TextAlign.center,
            style: tt.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
            enabled: SettingsProvider.maybeOf(context)?.bionicReadingEnabled ?? false,
          ),
          const SizedBox(height: AppSpacing.md),
          BionicText(
            text: data.body,
            textAlign: TextAlign.center,
            style: tt.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.6,
            ),
            enabled: SettingsProvider.maybeOf(context)?.bionicReadingEnabled ?? false,
          ),
        ],
      ),
    );
  }
}
