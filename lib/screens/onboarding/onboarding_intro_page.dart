import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/atoms/bionic_text.dart';
import '../../widgets/atoms/glow_box.dart';
import 'onboarding_page_data.dart';

/// A single intro/feature page shown during onboarding.
class OnboardingIntroPage extends StatelessWidget {
  const OnboardingIntroPage({super.key, required this.data});

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final iconBubble = GlowBox(
      color: cs.primary,
      glowOpacity: 0.5,
      blurRadius: 32,
      spreadRadius: 4,
      shape: BoxShape.circle,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(data.icon, size: 48, color: cs.onPrimaryContainer),
      ),
    );

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
            child: iconBubble,
          ),
          const SizedBox(height: AppSpacing.xl),
          Animate(
            effects: [
              FadeEffect(
                delay: 120.ms,
                duration: 500.ms,
                curve: Curves.easeOut,
              ),
              SlideEffect(
                delay: 120.ms,
                begin: const Offset(0, 0.15),
                end: Offset.zero,
                duration: 550.ms,
                curve: AppMotion.emphasizedDecelerate,
              ),
            ],
            child: BionicText(
              text: data.title,
              textAlign: TextAlign.center,
              style: tt.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
              enabled:
                  SettingsProvider.maybeOf(context)?.bionicReadingEnabled ??
                  false,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Animate(
            effects: [
              FadeEffect(
                delay: 220.ms,
                duration: 500.ms,
                curve: Curves.easeOut,
              ),
              SlideEffect(
                delay: 220.ms,
                begin: const Offset(0, 0.15),
                end: Offset.zero,
                duration: 550.ms,
                curve: AppMotion.emphasizedDecelerate,
              ),
            ],
            child: BionicText(
              text: data.body,
              textAlign: TextAlign.center,
              style: tt.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.6,
              ),
              enabled:
                  SettingsProvider.maybeOf(context)?.bionicReadingEnabled ??
                  false,
            ),
          ),
        ],
      ),
    );
  }
}
