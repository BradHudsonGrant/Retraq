import 'package:flutter/material.dart';
import '../legal/privacy_policy.dart';
import '../legal/terms_of_service.dart';
import '../services/database_service.dart';
import '../services/user_repository.dart';
import '../theme/app_spacing.dart';
import '../utils/app_info.dart' as info;
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

  Future<void> _submit() async {
    if (!_privacyAccepted || !_termsAccepted) return;
    final userRepo = DatabaseService.instance.userRepo;
    final now = DateTime.now();
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
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Icon(
                  Icons.policy_outlined,
                  size: 64,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  'Updated Policies',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  "We've updated our Privacy Policy and/or Terms of Use. "
                  'Please review and accept to continue.',
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
                label: 'I have read and agree to the Privacy Policy',
                onTapLink: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LegalScreen(
                      title: 'Privacy Policy',
                      content: privacyPolicyText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ReconsentCheckbox(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                label: 'I agree to the Terms of Use',
                onTapLink: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LegalScreen(
                      title: 'Terms of Use',
                      content: termsOfServiceText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: FilledButton(
                  onPressed: _privacyAccepted && _termsAccepted ? _submit : null,
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: tt.labelLarge,
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
            child: Center(
              child: Checkbox(value: value, onChanged: onChanged),
            ),
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
