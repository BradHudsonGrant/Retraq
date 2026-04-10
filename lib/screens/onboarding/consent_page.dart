import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/atoms/bionic_text.dart';
import '../../widgets/atoms/glow_box.dart';
import '../../legal/privacy_policy.dart';
import '../../legal/health_disclaimer.dart';
import '../../legal/terms_of_service.dart';
import '../legal_screen.dart';

/// Consent page where users accept privacy policy, terms, and health disclaimer.
class ConsentPage extends StatelessWidget {
  const ConsentPage({
    super.key,
    required this.privacyAccepted,
    required this.termsAccepted,
    required this.healthAccepted,
    required this.onPrivacyChanged,
    required this.onTermsChanged,
    required this.onHealthChanged,
  });

  final bool privacyAccepted;
  final bool termsAccepted;
  final bool healthAccepted;
  final ValueChanged<bool?> onPrivacyChanged;
  final ValueChanged<bool?> onTermsChanged;
  final ValueChanged<bool?> onHealthChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Animate(
              effects: [
                FadeEffect(duration: 500.ms, curve: Curves.easeOut),
                ScaleEffect(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: AppMotion.springSmooth,
                ),
              ],
              child: GlowBox(
                color: cs.primary,
                glowOpacity: 0.55,
                blurRadius: 32,
                spreadRadius: 4,
                shape: BoxShape.circle,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: ExcludeSemantics(
                    child: Icon(
                      Icons.handshake_outlined,
                      size: 36,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: BionicText(
              text: l10n.almostThere,
              style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
              enabled:
                  SettingsProvider.maybeOf(context)?.bionicReadingEnabled ??
                  false,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Health disclaimer info
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer.withValues(alpha: 0.4),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: cs.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: BionicText(
                    text: l10n.healthDisclaimer,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onTertiaryContainer,
                      height: 1.5,
                    ),
                    enabled:
                        SettingsProvider.maybeOf(
                          context,
                        )?.bionicReadingEnabled ??
                        false,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Health disclaimer checkbox
          _ConsentCheckbox(
            value: healthAccepted,
            onChanged: onHealthChanged,
            label: l10n.healthDisclaimerCheckbox,
            onTapLink:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder:
                        (_) => LegalScreen(
                          title: l10n.healthDisclaimerTitle,
                          content: healthDisclaimerText,
                        ),
                  ),
                ),
            colorScheme: cs,
            textTheme: tt,
          ),

          const SizedBox(height: AppSpacing.md),

          // Privacy policy checkbox
          _ConsentCheckbox(
            value: privacyAccepted,
            onChanged: onPrivacyChanged,
            label: l10n.privacyPolicyCheckbox,
            onTapLink:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder:
                        (_) => LegalScreen(
                          title: l10n.privacyPolicy,
                          content: privacyPolicyText,
                        ),
                  ),
                ),
            colorScheme: cs,
            textTheme: tt,
          ),

          const SizedBox(height: AppSpacing.md),

          // Terms checkbox
          _ConsentCheckbox(
            value: termsAccepted,
            onChanged: onTermsChanged,
            label: l10n.termsCheckbox,
            onTapLink:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder:
                        (_) => LegalScreen(
                          title: l10n.termsOfUse,
                          content: termsOfServiceText,
                        ),
                  ),
                ),
            colorScheme: cs,
            textTheme: tt,
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _ConsentCheckbox extends StatelessWidget {
  const _ConsentCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.onTapLink,
    required this.colorScheme,
    required this.textTheme,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final VoidCallback onTapLink;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: AppSpacing.borderRadiusLg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Center(child: Checkbox(value: value, onChanged: onChanged)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: InkWell(
                onTap: onTapLink,
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
