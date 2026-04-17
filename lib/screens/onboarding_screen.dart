import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/app_log.dart';
import '../services/database_service.dart';
import '../services/locale_age_threshold.dart';
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
  // Task 2.6 — true when a prior consent marker was observed in
  // hardened secure storage at init time. Flags the "Welcome back"
  // copy on the consent page.
  bool _isReturningUser = false;

  // Consent state
  bool _privacyAccepted = false;
  bool _termsAccepted = false;
  bool _healthAccepted = false;

  static const _ageVerifiedKey = 'age_verified';
  // Task 2.6 — cross-install marker. Written on successful consent;
  // survives uninstall on Android devices that restore hardened
  // secure storage via Google Auto-Backup. Its presence lets us
  // collapse the marketing intros to a quick "Welcome back" path
  // while consent ITSELF remains a regulatory gate (never auto-
  // accepted). Value is the consent-version string at time of
  // previous completion — lets us trigger the normal re-consent
  // flow when versions diverge rather than skipping past it.
  static const priorConsentSecureKey = 'onboarding_prior_consent_version';

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
    } catch (e, st) {
      // Task 1.4 — secure storage unavailability in tests is expected;
      // log it via AppLog so real prod failures surface while keeping
      // the graceful handle-as-not-denied fallback.
      AppLog.warn('OnboardingScreen.checkAgeDenied', e, st);
    }

    final prefs = await SharedPreferences.getInstance();
    final verified = prefs.getBool(_ageVerifiedKey) ?? false;

    // Task 2.6 — if prior consent was recorded (cross-install marker
    // survives uninstall via Android auto-backup), collapse the
    // marketing intro pages so the returning user lands directly on
    // the consent page. Consent itself is NOT skipped — it's still
    // a regulatory gate — but the 3 intro pages behind it become
    // friction with no compliance benefit for a user who has seen
    // them before.
    String? priorConsent;
    try {
      priorConsent = await hardenedSecureStorage.read(
        key: priorConsentSecureKey,
      );
    } catch (e, st) {
      AppLog.warn('OnboardingScreen.checkPriorConsent', e, st);
    }

    if (denied && mounted) {
      setState(() {
        _ageDenied = true;
        _initialized = true;
      });
    } else if (verified && priorConsent != null && mounted) {
      // Returning user: skip past age gate + 3 intros, land on consent.
      final consentPageIndex = _totalPageCount - 1;
      _controller.dispose();
      _controller = PageController(initialPage: consentPageIndex);
      setState(() {
        _currentPage = consentPageIndex;
        _isReturningUser = true;
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
      // Task 2.6 — write the cross-install marker so a subsequent
      // reinstall (on a device with Google Auto-Backup or iOS
      // Keychain sync) lands directly on the consent page next time.
      // The value is a coarse composite of all three versions so any
      // bump forces the full re-consent flow.
      try {
        await hardenedSecureStorage.write(
          key: priorConsentSecureKey,
          value: '$currentPrivacyPolicyVersion|'
              '$currentTermsOfServiceVersion|'
              '$currentHealthDisclaimerVersion',
        );
      } catch (e, st) {
        // Non-fatal: secure-storage writes can fail on hostile envs
        // or tests. The consent records in Drift are the source of
        // truth; this marker is a pure UX shortcut for reinstalls.
        AppLog.warn('OnboardingScreen.writePriorConsentMarker', e, st);
      }
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
      } catch (e, st) {
        // Task 1.4 — permission request failures shouldn't block
        // onboarding, but we still want them captured so we can spot
        // platform regressions. Non-fatal; continue.
        AppLog.warn('OnboardingScreen.requestNotificationPermission', e, st);
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
    } catch (e, st) {
      // Task 1.4 — log but continue; the in-memory _ageDenied flag
      // still guards the UI for this session even if persistence
      // fails (secure storage may be unavailable in tests or on
      // hostile devices).
      AppLog.warn('OnboardingScreen.persistAgeDenial', e, st);
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
                        // Task 12.3 — resolve the country-aware age
                        // threshold from the device locale at build
                        // time. Falls back to the COPPA baseline 13
                        // when the platform provides no region.
                        final localeTag = Localizations.localeOf(
                          context,
                        ).toLanguageTag();
                        final region = regionFromLocaleTag(localeTag);
                        final minAge = ageThresholdForCountry(region);
                        return AgeGatePage(
                          onConfirm: _confirmAge,
                          onDeny: _denyAge,
                          isDenied: _ageDenied,
                          minAge: minAge,
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
                        isReturningUser: _isReturningUser,
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
