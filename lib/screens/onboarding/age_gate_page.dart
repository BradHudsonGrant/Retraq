import 'package:flutter/material.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/atoms/bionic_text.dart';

/// Age verification page shown at the start of onboarding.
class AgeGatePage extends StatelessWidget {
  const AgeGatePage({
    super.key,
    required this.onConfirm,
    required this.onDeny,
    required this.isDenied,
  });

  final VoidCallback onConfirm;
  final VoidCallback onDeny;
  final bool isDenied;

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
              color: isDenied ? cs.errorContainer : cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDenied ? Icons.block : Icons.verified_user,
              size: 48,
              color: isDenied ? cs.onErrorContainer : cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          BionicText(
            text: isDenied ? 'Sorry!' : 'Before we begin',
            textAlign: TextAlign.center,
            style: tt.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
            enabled: SettingsProvider.maybeOf(context)?.bionicReadingEnabled ?? false,
          ),
          const SizedBox(height: AppSpacing.md),
          BionicText(
            text: isDenied
                ? 'SinceThen requires users to be 13 years or older.\n'
                    'Please come back when you\'re old enough!'
                : 'SinceThen is designed for users\naged 13 and older.',
            textAlign: TextAlign.center,
            style: tt.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.6,
            ),
            enabled: SettingsProvider.maybeOf(context)?.bionicReadingEnabled ?? false,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (!isDenied) ...[
            FilledButton(
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
                'I am 13 or older',
                style: tt.labelLarge?.copyWith(
                  color: cs.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onDeny,
              child: Text(
                'I am under 13',
                style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
