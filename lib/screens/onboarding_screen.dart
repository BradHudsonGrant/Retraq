import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/user_repository.dart';
import '../theme/app_spacing.dart';
import '../legal/privacy_policy.dart';
import '../legal/health_disclaimer.dart';
import '../legal/terms_of_service.dart';
import '../widgets/atoms/sincethen_logo.dart';
import '../widgets/molecules/page_indicator_dots.dart';
import 'legal_screen.dart';
import '../utils/app_info.dart' as info;

/// First-launch onboarding — age gate, 3 intro screens, and consent.
/// Follows the ADHD principle: minimal, warm, zero overwhelm.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  PageController _controller = PageController();
  int _currentPage = 0;
  bool _ageDenied = false;
  bool _initialized = false;

  // Consent state
  bool _privacyAccepted = false;
  bool _termsAccepted = false;
  bool _healthAccepted = false;

  static const _ageVerifiedKey = 'age_verified';
  static const _ageDeniedKey = 'age_denied';

  static const _pages = [
    _PageData(
      icon: Icons.edit_note,
      title: 'Your day,\nyour words.',
      body: 'No templates. No pressure.\nJust jot down the highlights.',
    ),
    _PageData(
      icon: Icons.auto_awesome,
      title: 'Look back\nwithout stress.',
      body: 'A simple calendar shows\nwhat you captured each day.',
    ),
    _PageData(
      icon: Icons.lock_outline,
      title: 'Private\nby default.',
      body: 'Everything stays on your phone.\nNo account needed. Ever.',
    ),
  ];

  /// Total page count: age gate + info pages + consent page.
  int get _totalPageCount => _pages.length + 2;

  @override
  void initState() {
    super.initState();
    _checkAgeVerified();
  }

  Future<void> _checkAgeVerified() async {
    final prefs = await SharedPreferences.getInstance();
    final verified = prefs.getBool(_ageVerifiedKey) ?? false;
    final denied = prefs.getBool(_ageDeniedKey) ?? false;
    if (verified && mounted) {
      _controller.dispose();
      _controller = PageController(initialPage: 1);
      setState(() {
        _currentPage = 1;
        _initialized = true;
      });
    } else if (denied && mounted) {
      setState(() {
        _ageDenied = true;
        _initialized = true;
      });
    } else if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final lastPage = _totalPageCount - 1;
    if (_currentPage < lastPage) {
      _controller.nextPage(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else if (_currentPage == lastPage) {
      // Consent page — only complete if both accepted
      if (_privacyAccepted && _termsAccepted && _healthAccepted) {
        await _saveConsentRecords();
        if (mounted) await _showNotificationPrePrompt();
        widget.onComplete();
      }
    }
  }

  Future<void> _saveConsentRecords() async {
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
    await userRepo.saveConsentRecord(
      consentType: 'health_disclaimer',
      documentVersion: currentHealthDisclaimerVersion,
      acceptedAt: now,
      appVersion: info.appVersion,
    );
  }

  Future<void> _showNotificationPrePrompt() async {
    final shouldEnable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.notifications_outlined, size: 32),
        title: const Text('Stay on track'),
        content: const Text(
          'A gentle daily reminder can help you build a journaling habit. '
          'You can change or turn this off anytime in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enable reminders'),
          ),
        ],
      ),
    );
    if (shouldEnable == true) {
      try {
        await NotificationService.instance.requestPermission();
      } catch (_) {
        // Non-fatal — some platforms may not support this
      }
    }
  }

  Future<void> _confirmAge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ageVerifiedKey, true);
    if (!mounted) return;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    _controller.nextPage(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _denyAge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ageDeniedKey, true);
    if (!mounted) return;
    setState(() => _ageDenied = true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (!_initialized) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: const SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Logo only (no Skip — consent is required)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.md,
                top: AppSpacing.md,
              ),
              child: Row(
                children: [
                  const SinceThenLogo(size: 32, animate: true, showText: true),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _totalPageCount,
                onPageChanged: (i) => setState(() => _currentPage = i),
                physics: _currentPage == 0
                    ? const NeverScrollableScrollPhysics()
                    : null,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return _AgeGatePage(
                      onConfirm: _confirmAge,
                      onDeny: _denyAge,
                      isDenied: _ageDenied,
                    );
                  }
                  if (i <= _pages.length) {
                    return _OnboardingPage(data: _pages[i - 1]);
                  }
                  // Last page: consent
                  return _ConsentPage(
                    privacyAccepted: _privacyAccepted,
                    termsAccepted: _termsAccepted,
                    healthAccepted: _healthAccepted,
                    onPrivacyChanged: (v) =>
                        setState(() => _privacyAccepted = v ?? false),
                    onTermsChanged: (v) =>
                        setState(() => _termsAccepted = v ?? false),
                    onHealthChanged: (v) =>
                        setState(() => _healthAccepted = v ?? false),
                  );
                },
              ),
            ),

            // Dots + button (hidden on age gate page)
            if (_currentPage > 0)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page dots (info pages + consent = _pages.length + 1)
                    Semantics(
                      label: 'Page $_currentPage of ${_totalPageCount - 1}',
                      excludeSemantics: true,
                      child: PageIndicatorDots(
                        count: _pages.length + 1,
                        current: _currentPage - 1,
                      ),
                    ),

                    // Next / Get Started button
                    FilledButton(
                      onPressed: _isNextEnabled ? _next : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      child: Text(
                        _currentPage == _totalPageCount - 1
                            ? 'Get Started'
                            : 'Next',
                        style: tt.labelLarge?.copyWith(
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get _isNextEnabled {
    // On consent page, require all checkboxes
    if (_currentPage == _totalPageCount - 1) {
      return _privacyAccepted && _termsAccepted && _healthAccepted;
    }
    return true;
  }
}

class _PageData {
  const _PageData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _AgeGatePage extends StatelessWidget {
  const _AgeGatePage({
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
          Text(
            isDenied ? 'Sorry!' : 'Before we begin',
            textAlign: TextAlign.center,
            style: tt.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isDenied
                ? 'SinceThen requires users to be 13 years or older.\n'
                    'Please come back when you\'re old enough!'
                : 'SinceThen is designed for users\naged 13 and older.',
            textAlign: TextAlign.center,
            style: tt.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.6,
            ),
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

class _ConsentPage extends StatelessWidget {
  const _ConsentPage({
    required this.privacyAccepted,
    required this.termsAccepted,
    required this.healthAccepted,
    required this.onPrivacyChanged,
    required this.onTermsChanged,
    required this.onHealthChanged,
  });

  final bool privacyAccepted;
  final bool termsAccepted;
  final bool healthAccepted;
  final ValueChanged<bool?> onPrivacyChanged;
  final ValueChanged<bool?> onTermsChanged;
  final ValueChanged<bool?> onHealthChanged;

  static const _healthDisclaimer =
      'SinceThen is a personal journaling app — not a medical or therapeutic '
      'tool. It does not provide health advice, diagnosis, or treatment. If '
      'you are in crisis, please contact a mental health professional or call '
      '988 (Suicide & Crisis Lifeline).';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: ExcludeSemantics(child: Icon(Icons.handshake_outlined, size: 36,
                  color: cs.onPrimaryContainer)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              'Almost there!',
              style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
                ExcludeSemantics(child: Icon(Icons.info_outline, size: 20,
                    color: cs.onTertiaryContainer)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _healthDisclaimer,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onTertiaryContainer,
                      height: 1.5,
                    ),
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
            label: 'I acknowledge the Health Disclaimer',
            onTapLink: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LegalScreen(
                  title: 'Health Disclaimer',
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
            label: 'I have read and agree to the Privacy Policy',
            onTapLink: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LegalScreen(
                  title: 'Privacy Policy',
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
            label: 'I agree to the Terms of Use',
            onTapLink: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LegalScreen(
                  title: 'Terms of Use',
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
              child: Checkbox(
                value: value,
                onChanged: onChanged,
              ),
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
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _PageData data;

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
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 48, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: tt.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: tt.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
