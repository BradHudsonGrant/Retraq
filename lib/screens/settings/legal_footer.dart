import 'package:flutter/material.dart';
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

    return Center(
      child: Column(
        children: [
          Text(
            '${info.appName} Version ${info.appVersion}',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegalLink(
                label: 'Privacy Policy',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LegalScreen(
                      title: 'Privacy Policy',
                      content: privacyPolicyText,
                    ),
                  ),
                ),
              ),
              _dot(cs, tt),
              _LegalLink(
                label: 'Terms',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LegalScreen(
                      title: 'Terms of Service',
                      content: termsOfServiceText,
                    ),
                  ),
                ),
              ),
              _dot(cs, tt),
              _LegalLink(
                label: 'Health',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LegalScreen(
                      title: 'Health Disclaimer',
                      content: healthDisclaimerText,
                    ),
                  ),
                ),
              ),
              _dot(cs, tt),
              _LegalLink(
                label: 'Licenses',
                onPressed: () => showLicensePage(
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
