import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/secure_storage.dart';
import '../services/user_repository.dart';
import '../theme/app_spacing.dart';
import '../widgets/atoms/animated_mesh_background.dart';
import '../widgets/atoms/app_snack_bar.dart';
import '../widgets/atoms/glow_box.dart';
import '../widgets/atoms/retraq_logo.dart';
import '../widgets/molecules/page_indicator_dots.dart';
import '../utils/app_info.dart' as info;
import 'onboarding/age_gate_page.dart';
import 'onboarding/consent_page.dart';
import 'onboarding/onboarding_intro_page.dart';
import 'onboarding/onboarding_page_data.dart';

/// First-launch onboarding — age gate, 3 intro screens, and consent.
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

  /// Secure-storage key for the COPPA under-13 denial flag.
  ///
  /// Persisted in [hardenedSecureStorage] (not SharedPreferences) so it
  /// survives force-stop and is not trivially clearable. The only escape
  /// hatch is uninstall/reinstall, which is high-friction enough to satisfy
  /// FTC COPPA "neutral age screen" guidance.
  static const ageDeniedSecureKey = 'coppa_age_denied';

  /// Number of intro pages (excluding age gate and consent).
  static const _introPageCount = 3;

  /// Builds the localized onboarding intro pages from the branding guide.
  List<OnboardingPageData> _buildPages(L10n l10n) {
    return [
      OnboardingPageData(
        icon: Icons.psychology_outlined,
        title: l10n.onboardingTitle1,
        body: l10n.onboardingBody1,
      ),
      OnboardingPageData(
        icon: Icons.edit_outlined,
        title: l10n.onboardingTitle2,
        body: l10n.onboardingBody2,
      ),
      OnboardingPageData(
        icon: Icons.tune_outlined,
        title: l10n.onboardingTitle3,
        body: l10n.onboardingBody3,
      ),
    ];
  }

  /// Total page count: age gate + info pages + consent page.
  int get _totalPageCount => _introPageCount + 2;

  @override
  void initState() {
    super.initState();
    _checkAgeVerified();
  }

  Future<void> _checkAgeVerified() async {
    // COPPA: check the denial flag FIRST from secure storage. If a user
    // has previously declared under-13, we render the denial screen
    // immediately without re-prompting, even across force-stops.
    bool denied = false;
    try {
      denied =
          (await hardenedSecureStorage.read(key: ageDeniedSecureKey)) == 'true';
    } catch (_) {
      // SecureStorage may not be available in test environments;
      // fall through and treat as not-denied.
    }

    final prefs = await SharedPreferences.getInstance();
    final verified = prefs.getBool(_ageVerifiedKey) ?? false;

    if (denied && mounted) {
      setState(() {
        _ageDenied = true;
        _initialized = true;
      });
    } else if (verified && mounted) {
      _controller.dispose();
      _controller = PageController(initialPage: 1);
      setState(() {
        _currentPage = 1;
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
      if (reduceMotion) {
        _controller.jumpToPage(_currentPage + 1);
      } else {
        _controller.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentPage == lastPage) {
      // Consent page — only complete if both accepted
      if (_privacyAccepted && _termsAccepted && _healthAccepted) {
        final saved = await _saveConsentRecords();
        if (!saved) return; // SnackBar already shown; let user retry
        if (mounted) await _showNotificationPrePrompt();
        widget.onComplete();
      }
    }
  }

  /// Returns true if all consent records saved successfully.
  Future<bool> _saveConsentRecords() async {
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
      return true;
    } catch (e) {
      debugPrint('Failed to save consent records: $e');
      if (mounted) {
        AppSnackBar.show(context, L10n.of(context)!.consentSaveFailed);
      }
      return false;
    }
  }

  Future<void> _showNotificationPrePrompt() async {
    final l10n = L10n.of(context)!;
    final shouldEnable = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            icon: const Icon(Icons.notifications_outlined, size: 32),
            title: Text(l10n.notificationDialogTitle),
            content: Text(l10n.notificationDialogContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.notNow),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.enableReminders),
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
    if (reduceMotion) {
      _controller.jumpToPage(_currentPage + 1);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _denyAge() async {
    // COPPA: persist denial to secure storage so it survives force-stop.
    // There is intentionally no inverse "retry" method — per FTC guidance
    // the age screen must be neutral and must not nudge a user to re-declare.
    try {
      await hardenedSecureStorage.write(key: ageDeniedSecureKey, value: 'true');
    } catch (_) {
      // SecureStorage may not be available in test environments.
    }
    if (!mounted) return;
    setState(() => _ageDenied = true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;
    final pages = _buildPages(l10n);

    if (!_initialized) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: const SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AnimatedMeshBackground(
              colors: [
                cs.primary.withValues(alpha: 0.30),
                cs.tertiary.withValues(alpha: 0.22),
                cs.secondaryContainer.withValues(alpha: 0.30),
              ],
              baseColor: cs.surface,
              opacity: 0.45,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header: Logo only (no Skip — consent is required)
                const Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.xl,
                    right: AppSpacing.md,
                    top: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      RetraqLogo(size: 32, animate: true, showText: true),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _totalPageCount,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return AgeGatePage(
                          onConfirm: _confirmAge,
                          onDeny: _denyAge,
                          isDenied: _ageDenied,
                        );
                      }
                      if (i <= pages.length) {
                        return OnboardingIntroPage(data: pages[i - 1]);
                      }
                      // Last page: consent
                      return ConsentPage(
                        privacyAccepted: _privacyAccepted,
                        termsAccepted: _termsAccepted,
                        healthAccepted: _healthAccepted,
                        onPrivacyChanged:
                            (v) =>
                                setState(() => _privacyAccepted = v ?? false),
                        onTermsChanged:
                            (v) => setState(() => _termsAccepted = v ?? false),
                        onHealthChanged:
                            (v) => setState(() => _healthAccepted = v ?? false),
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
                        // Page dots (info pages + consent = pages.length + 1)
                        Semantics(
                          label: l10n.onboardingPageLabel(
                            _currentPage,
                            _totalPageCount - 1,
                          ),
                          excludeSemantics: true,
                          child: PageIndicatorDots(
                            count: pages.length + 1,
                            current: _currentPage - 1,
                          ),
                        ),

                        // Next / Get Started button
                        GlowBox(
                          color: cs.primary,
                          glowOpacity: _isNextEnabled ? 0.55 : 0.0,
                          blurRadius: 26,
                          spreadRadius: 2,
                          borderRadius: AppSpacing.borderRadiusFull,
                          child: FilledButton(
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
                                  ? l10n.getStartedButton
                                  : l10n.nextButton,
                              style: tt.labelLarge?.copyWith(
                                color: cs.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
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
