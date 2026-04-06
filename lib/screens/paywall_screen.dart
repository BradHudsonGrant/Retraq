import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../theme/app_spacing.dart';

/// Paywall screen showing premium features and purchase options.
///
/// This is a scaffold — product IDs and pricing will be populated
/// once RevenueCat offerings are configured.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final SubscriptionService _subscriptionService =
      SubscriptionService.instance;

  bool _loading = false;

  Future<void> _onSubscribe() async {
    setState(() => _loading = true);

    // TODO: Fetch offerings and present the correct package.
    // final offerings = await _subscriptionService.getOfferings();
    // if (offerings?.current?.availablePackages.isNotEmpty == true) {
    //   await _subscriptionService.purchasePackage(
    //     offerings!.current!.availablePackages.first,
    //   );
    // }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _onRestore() async {
    setState(() => _loading = true);

    final restored = await _subscriptionService.restorePurchases();

    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? 'Purchases restored successfully.'
              : 'No previous purchases found.',
        ),
      ),
    );

    if (restored) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Premium'),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding.copyWith(
            top: AppSpacing.lg,
            bottom: AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Icon(
                Icons.workspace_premium_rounded,
                size: 64,
                color: cs.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Unlock Premium',
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Get the most out of Retraq with premium features.',
                style: tt.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Feature list ──
              _FeatureRow(
                icon: Icons.insights_rounded,
                title: 'Advanced Insights',
                subtitle: 'Deeper analytics and trends over time.',
              ),
              const SizedBox(height: AppSpacing.md),
              _FeatureRow(
                icon: Icons.cloud_sync_rounded,
                title: 'Cloud Backup',
                subtitle: 'Automatic encrypted backups across devices.',
              ),
              const SizedBox(height: AppSpacing.md),
              _FeatureRow(
                icon: Icons.palette_rounded,
                title: 'Custom Themes',
                subtitle: 'Personalize your journaling experience.',
              ),

              const Spacer(),

              // ── Buttons ──
              FilledButton(
                onPressed: _loading ? null : _onSubscribe,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Subscribe'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _loading ? null : _onRestore,
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Restore Purchases'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Icon(icon, color: cs.onPrimaryContainer),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
