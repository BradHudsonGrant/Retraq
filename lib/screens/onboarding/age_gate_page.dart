import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/settings_provider.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/atoms/bionic_text.dart';
import '../../widgets/atoms/glow_box.dart';

/// Age verification page shown at the start of onboarding.
///
/// [minAge] is resolved from the device locale (13 / 14 /
/// 16 per COPPA + GDPR Art. 8 + Quebec Law 25). See
/// `lib/services/locale_age_threshold.dart` for the full table and
/// callers in `onboarding_screen.dart` for resolution.
class AgeGatePage extends StatelessWidget {
  const AgeGatePage({
    super.key,
    required this.onConfirm,
    required this.onDeny,
    required this.isDenied,
    this.minAge = 13,
  });

  final VoidCallback onConfirm;
  final VoidCallback onDeny;
  final bool isDenied;
  final int minAge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Animate(
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
              color: isDenied ? cs.error : cs.primary,
              glowOpacity: 0.55,
              blurRadius: 36,
              spreadRadius: 4,
              shape: BoxShape.circle,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: isDenied ? cs.errorContainer : cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDenied ? Icons.block : Icons.verified_user,
                  size: 48,
                  color: isDenied ? cs.onErrorContainer : cs.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          BionicText(
            text: isDenied ? l10n.ageGateDeniedTitle : l10n.ageGateTitle,
            textAlign: TextAlign.center,
            style: tt.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
            enabled:
                SettingsProvider.maybeOf(context)?.bionicReadingEnabled ??
                false,
          ),
          const SizedBox(height: AppSpacing.md),
          BionicText(
            text: isDenied
                ? l10n.ageGateDenied(minAge)
                : l10n.ageGateMessage(minAge),
            textAlign: TextAlign.center,
            style: tt.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.6,
            ),
            enabled:
                SettingsProvider.maybeOf(context)?.bionicReadingEnabled ??
                false,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (!isDenied) ...[
            GlowBox(
              color: cs.primary,
              glowOpacity: 0.55,
              blurRadius: 26,
              spreadRadius: 2,
              borderRadius: AppSpacing.borderRadiusFull,
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                child: Text(
                  l10n.ageConfirmButton(minAge),
                  style: tt.labelLarge?.copyWith(color: cs.onPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onDeny,
              child: Text(
                l10n.ageDenyButton(minAge),
                style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ] else ...[
            BionicText(
              text: l10n.ageGateContactGuardian,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
              enabled:
                  SettingsProvider.maybeOf(context)?.bionicReadingEnabled ??
                  false,
            ),
          ],
        ],
      ),
    );
  }
}
