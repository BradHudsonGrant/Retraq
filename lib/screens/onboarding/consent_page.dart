import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/settings_provider.dart';
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
    this.isReturningUser = false,
  });

  final bool privacyAccepted;
  final bool termsAccepted;
  final bool healthAccepted;
  final ValueChanged<bool?> onPrivacyChanged;
  final ValueChanged<bool?> onTermsChanged;
  final ValueChanged<bool?> onHealthChanged;

  /// true when a cross-install consent marker was
  /// observed in hardened secure storage. Swaps the title from
  /// "Almost there!" to "Welcome back" and adds a subtitle
  /// explaining why consent is still required despite the marker.
  final bool isReturningUser;

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
              // swap headline for returning users (prior
              // consent marker present). Consent ITSELF is still a
              // regulatory gate — only the intros are skipped.
              text: isReturningUser ? l10n.welcomeBackTitle : l10n.almostThere,
              style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
              enabled:
                  SettingsProvider.maybeOf(context)?.bionicReadingEnabled ??
                  false,
            ),
          ),
          if (isReturningUser) ...[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                child: Text(
                  l10n.welcomeBackSubtitle,
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
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
    // Split the consent row into two distinct tap targets
    // so tapping the label toggles the checkbox (the expected
    // behaviour) and a separate "View" button opens the legal
    // document. Previously the underlined Text intercepted taps and
    // routed to the legal screen, which is a subtle consent-capture
    // footgun when users try to tick the box by tapping the text.
    final l10n = L10n.of(context)!;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: AppSpacing.borderRadiusLg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton.icon(
            onPressed: onTapLink,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(l10n.viewLabel),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
