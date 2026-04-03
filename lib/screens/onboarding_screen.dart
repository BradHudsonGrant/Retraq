import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/user_repository.dart';
import '../theme/app_spacing.dart';
import '../widgets/atoms/sincethen_logo.dart';
import '../widgets/molecules/page_indicator_dots.dart';
import '../utils/app_info.dart' as info;
import 'onboarding/age_gate_page.dart';
import 'onboarding/consent_page.dart';
import 'onboarding/onboarding_intro_page.dart';
import 'onboarding/onboarding_page_data.dart';

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
    OnboardingPageData(
      icon: Icons.edit_note,
      title: 'Your day,\nyour words.',
      body: 'No templates. No pressure.\nJust jot down the highlights.',
    ),
    OnboardingPageData(
      icon: Icons.auto_awesome,
      title: 'Look back\nwithout stress.',
      body: 'A simple calendar shows\nwhat you captured each day.',
    ),
    OnboardingPageData(
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
                    return AgeGatePage(
                      onConfirm: _confirmAge,
                      onDeny: _denyAge,
                      isDenied: _ageDenied,
                    );
                  }
                  if (i <= _pages.length) {
                    return OnboardingIntroPage(data: _pages[i - 1]);
                  }
                  // Last page: consent
                  return ConsentPage(
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
