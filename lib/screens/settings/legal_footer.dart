import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../../utils/app_info.dart' as info;
import '../../legal/privacy_policy.dart';
import '../../legal/terms_of_service.dart';
import '../../legal/health_disclaimer.dart';
import '../legal_screen.dart';

class LegalFooter extends StatelessWidget {
  const LegalFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    return Center(
      child: Column(
        children: [
          Text(
            l10n.settingsLegalFooter(info.appName, info.appVersion),
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegalLink(
                label: l10n.privacyPolicy,
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => LegalScreen(
                              title: l10n.privacyPolicy,
                              content: privacyPolicyText,
                            ),
                      ),
                    ),
              ),
              _dot(cs, tt),
              _LegalLink(
                label: l10n.legalFooterTerms,
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => LegalScreen(
                              title: l10n.termsOfService,
                              content: termsOfServiceText,
                            ),
                      ),
                    ),
              ),
              _dot(cs, tt),
              _LegalLink(
                label: l10n.legalFooterHealth,
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => LegalScreen(
                              title: l10n.healthDisclaimerTitle,
                              content: healthDisclaimerText,
                            ),
                      ),
                    ),
              ),
              _dot(cs, tt),
              _LegalLink(
                label: l10n.legalFooterLicenses,
                onPressed:
                    () => showLicensePage(
                      context: context,
                      applicationName: info.appName,
                      applicationVersion: info.appVersion,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(ColorScheme cs, TextTheme tt) {
    return Text(
      '·',
      style: tt.labelSmall?.copyWith(
        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}
