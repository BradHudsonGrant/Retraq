import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../l10n/app_localizations.dart';
import '../legal/health_disclaimer.dart';
import '../legal/privacy_policy.dart';
import '../legal/terms_of_service.dart';
import '../services/database_service.dart';
import '../services/user_repository.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../utils/app_info.dart' as info;
import '../widgets/atoms/glow_box.dart';
import 'legal_screen.dart';

/// Shown when the user has already completed onboarding but the privacy
/// policy or terms of service have been updated since they last consented.
class ReconsentScreen extends StatefulWidget {
  const ReconsentScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<ReconsentScreen> createState() => _ReconsentScreenState();
}

class _ReconsentScreenState extends State<ReconsentScreen> {
  bool _privacyAccepted = false;
  bool _termsAccepted = false;
  bool _healthDisclaimerAccepted = false;

  Future<void> _submit() async {
    if (!_privacyAccepted || !_termsAccepted || !_healthDisclaimerAccepted) {
      return;
    }
    final userRepo = DatabaseService.instance.userRepo;
    final now = DateTime.now();
    try {
      await userRepo.saveConsentRecord(
        consentType: 'privacy_policy',
        documentVersion: currentPrivacyPolicyVersion,
        acceptedAt: now,
        appVersion: info.appVersion,
      );
      await userRepo.saveConsentRecord(
        consentType: 'terms_of_service',
        documentVersion: currentTermsOfServiceVersion,
        acceptedAt: now,
        appVersion: info.appVersion,
      );
      await userRepo.saveConsentRecord(
        consentType: 'health_disclaimer',
        documentVersion: currentHealthDisclaimerVersion,
        acceptedAt: now,
        appVersion: info.appVersion,
      );
      widget.onComplete();
    } catch (e) {
      debugPrint('Failed to save consent records: $e');
      if (mounted) {
        final l10n = L10n.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.consentSaveFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),
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
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.policy_outlined,
                        size: 48,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  l10n.updatedPolicies,
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  l10n.reconsentMessage,
                  textAlign: TextAlign.center,
                  style: tt.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _ReconsentCheckbox(
                value: _privacyAccepted,
                onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
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
              ),
              const SizedBox(height: AppSpacing.md),
              _ReconsentCheckbox(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v ?? false),
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
              ),
              const SizedBox(height: AppSpacing.md),
              _ReconsentCheckbox(
                value: _healthDisclaimerAccepted,
                onChanged:
                    (v) =>
                        setState(() => _healthDisclaimerAccepted = v ?? false),
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
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: GlowBox(
                  color: cs.primary,
                  glowOpacity:
                      (_privacyAccepted &&
                              _termsAccepted &&
                              _healthDisclaimerAccepted)
                          ? 0.55
                          : 0.0,
                  blurRadius: 26,
                  spreadRadius: 2,
                  borderRadius: AppSpacing.borderRadiusFull,
                  child: FilledButton(
                    onPressed:
                        _privacyAccepted &&
                                _termsAccepted &&
                                _healthDisclaimerAccepted
                            ? _submit
                            : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                    ),
                    child: Text(l10n.continueButton, style: tt.labelLarge),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReconsentCheckbox extends StatelessWidget {
  const _ReconsentCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.onTapLink,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final VoidCallback onTapLink;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface,
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
