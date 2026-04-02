import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/purchase_service.dart';
import '../theme/app_spacing.dart';

/// Paywall screen — presents premium subscription options.
///
/// Premium unlocks: cloud AI weekly recap, advanced mood analytics.
/// Free tier keeps: core journaling, basic stats, template recap, mood tracking.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  /// Show the paywall as a modal bottom sheet. Returns true if user subscribed.
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      builder: (_) => const PaywallScreen(),
    );
    return result == true;
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _purchaseService = PurchaseService.instance;
  List<Package> _packages = [];
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final packages = await _purchaseService.fetchPackages();
    if (!mounted) return;
    setState(() {
      _packages = packages;
      _loading = false;
      if (packages.isEmpty) {
        _error = 'No subscription plans available right now. Please try again later.';
      }
    });
  }

  Future<void> _purchase(Package pkg) async {
    setState(() => _purchasing = true);
    final success = await _purchaseService.purchasePackage(pkg);
    if (!mounted) return;
    setState(() => _purchasing = false);
    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    final success = await _purchaseService.restore();
    if (!mounted) return;
    setState(() => _purchasing = false);
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous purchases found.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Premium badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: Text(
                  'SinceThen Pro',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'Unlock deeper insights',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Everything you love, plus powerful tools to understand your patterns.',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Feature list
              _FeatureRow(
                icon: Icons.auto_awesome,
                title: 'AI Weekly Recap',
                subtitle: 'Cloud-powered summaries of your week',
                cs: cs,
                tt: tt,
              ),
              const SizedBox(height: AppSpacing.md),
              _FeatureRow(
                icon: Icons.insights,
                title: 'Advanced Analytics',
                subtitle: 'Mood trends, patterns, and correlations',
                cs: cs,
                tt: tt,
              ),
              const SizedBox(height: AppSpacing.md),
              _FeatureRow(
                icon: Icons.star_outline,
                title: 'Priority Support',
                subtitle: 'Direct access to the dev team',
                cs: cs,
                tt: tt,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Packages / loading / error
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    _error!,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                for (final pkg in _packages) ...[
                  _PackageButton(
                    package_: pkg,
                    purchasing: _purchasing,
                    onTap: () => _purchase(pkg),
                    cs: cs,
                    tt: tt,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

              const SizedBox(height: AppSpacing.md),

              // Restore purchases
              TextButton(
                onPressed: _purchasing ? null : _restore,
                child: Text(
                  'Restore Purchases',
                  style: tt.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Free tier reminder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: Text(
                  'Free forever: journaling, mood tracking, basic stats, template recaps, and streaks.',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme cs;
  final TextTheme tt;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Icon(icon, size: 20, color: cs.onPrimaryContainer),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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

class _PackageButton extends StatelessWidget {
  final Package package_;
  final bool purchasing;
  final VoidCallback onTap;
  final ColorScheme cs;
  final TextTheme tt;

  const _PackageButton({
    required this.package_,
    required this.purchasing,
    required this.onTap,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final product = package_.storeProduct;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: purchasing ? null : onTap,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusLg,
          ),
        ),
        child: purchasing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                '${product.title} — ${product.priceString}',
                style: tt.labelLarge?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
