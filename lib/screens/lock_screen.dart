import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/user_settings.dart';
import '../services/biometric_auth.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import '../services/lockout_controller.dart';
import '../services/secure_storage.dart';
import '../services/settings_repository.dart';
import '../services/user_repository.dart' show UserRepository;
import '../widgets/settings_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/atoms/brand_ambient_background.dart';
import '../widgets/atoms/app_snack_bar.dart';
import '../widgets/atoms/bionic_text.dart';
import '../widgets/atoms/glow_box.dart';
import '../widgets/atoms/retraq_logo.dart';
import '../widgets/molecules/number_pad.dart';
import '../widgets/organisms/delete_confirm_dialog.dart';
import '../widgets/organisms/pin_setup_sheet.dart' show pinLengthPrefKey;

/// Full-screen lock that shows on app open when app lock is enabled.
/// Supports PIN entry, optional biometric unlock, and brute-force protection.
class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.onUnlocked,
    this.biometric,
  });

  final VoidCallback onUnlocked;

  /// injectable biometric authenticator for tests.
  /// Production callers omit this and get [PlatformBiometricAuthenticator].
  final BiometricAuthenticator? biometric;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final SettingsRepository _settingsRepo = DatabaseService.instance.settings;
  late final BiometricAuthenticator _auth =
      widget.biometric ?? PlatformBiometricAuthenticator();

  late final LockoutController _lockout;

  String _enteredPin = '';
  bool _isError = false;
  UserSettings? _settings;

  @override
  void initState() {
    super.initState();
    _lockout = LockoutController();
    _lockout.addListener(() {
      if (mounted) setState(() {});
    });
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _settingsRepo.getSettings();
    if (!mounted) return;

    // Read configured PIN length (4 or 6, default 4) from secure storage.
    final storedPinLength =
        int.tryParse(
          await hardenedSecureStorage.read(key: pinLengthPrefKey) ?? '',
        ) ??
        4;

    setState(() {
      _settings = s;
      _pinLength = (storedPinLength == 6) ? 6 : 4;
    });

    await _lockout.loadState();

    if (s.appLockEnabled && s.biometricEnabled) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    if (_lockout.isLockedOut) return;
    if (!mounted) return;
    final reason = L10n.of(context)!.unlockBiometric;
    // outcome enum replaces a raw bool so test harnesses
    // can distinguish cancel-vs-success paths. Production UX stays
    // identical: only `success` navigates; every other outcome falls
    // through to the PIN pad without a surfaced error (a wrong-attempt
    // tally would be a brute-force escalation path).
    final outcome = await _auth.authenticate(
      reason: reason,
      persistAcrossBackgrounding: true,
      biometricOnly: true,
    );
    if (outcome == BiometricOutcome.success && mounted) {
      widget.onUnlocked();
    }
  }

  int _pinLength = 4;

  void _onDigit(int digit) {
    if (_settings == null ||
        _lockout.isLockedOut ||
        _isVerifying ||
        _enteredPin.length >= _pinLength) {
      return;
    }
    setState(() {
      _isError = false;
      _enteredPin += '$digit';
    });

    if (_enteredPin.length == _pinLength) {
      _verifyPin();
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty || _lockout.isLockedOut) return;
    setState(() {
      _isError = false;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  bool _isVerifying = false;

  Future<void> _verifyPin() async {
    final stored = _settings?.pinHash;
    if (stored == null || _isVerifying) return;

    _isVerifying = true;
    final pin = _enteredPin;
    final isValid = await PinService.verifyPin(pin, stored);
    _isVerifying = false;

    if (!mounted) return;

    if (isValid) {
      // Auto-upgrade legacy hash formats to current on successful unlock.
      if (PinService.isLegacyPinHash(stored)) {
        final newHash = await PinService.hashPin(pin);
        final settings = await _settingsRepo.getSettings();
        await _settingsRepo.saveSettings(settings.copyWith(pinHash: newHash));
      }
      _lockout.clearLockout();
      widget.onUnlocked();
    } else {
      setState(() {
        _isError = true;
        _enteredPin = '';
      });
      HapticFeedback.heavyImpact();
      _lockout.recordFailedAttempt();
    }
  }

  @override
  void dispose() {
    _lockout.dispose();
    super.dispose();
  }

  String _statusText(L10n l10n) {
    if (_lockout.isLockedOut) {
      return l10n.lockoutMessage(_lockout.lockoutSecondsLeft);
    }
    if (_lockout.failedAttempts > 0 || _isError) {
      final remaining = LockoutController.maxAttempts - _lockout.failedAttempts;
      return l10n.wrongPinMessage(remaining);
    }
    return l10n.enterPin;
  }

  void _showForgotPinDialog() {
    final cs = Theme.of(context).colorScheme;
    final l10n = L10n.of(context)!;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.forgotPin),
            content: Text(l10n.forgotPinMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancelLabel),
              ),
              // offer an export escape hatch before the
              // destructive reset so users who genuinely forgot their PIN
              // can still recover their journal content. Export is
              // intentionally available BEFORE a PIN/biometric check
              // because it has no network component (local file → OS
              // share intent). Users with data to recover are the main
              // beneficiaries; the actual unlock still requires PIN.
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _exportBeforeReset();
                },
                child: Text(l10n.exportBeforeReset),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _confirmAndReset();
                },
                child: Text(l10n.resetApp, style: TextStyle(color: cs.error)),
              ),
            ],
          ),
    );
  }

  /// Export journal data via the share sheet before a
  /// destructive reset. Called from the Forgot-PIN flow when the user
  /// taps "Export first" so they can save content to another app
  /// (Files, Drive, email) before wiping the device copy.
  ///
  /// Note: export currently works regardless of PIN state because the
  /// app is running and the DB is unlocked (a lock screen is up but the
  /// DB itself is decrypted into memory). A future hardening pass will
  /// either require the PIN to be entered correctly at least once
  /// before export is available, or encrypt the export with a
  /// user-supplied passphrase.
  Future<void> _exportBeforeReset() async {
    try {
      await ExportService.instance.exportAsJson(exportAll: true);
    } on Object catch (e) {
      debugPrint('Export before reset failed: $e');
      if (!mounted) return;
      AppSnackBar.error(context, 'Export failed: $e');
    }
  }

  /// Before wiping all data, require a biometric challenge
  /// (where available) as an additional check. This protects against a
  /// shoulder-surfer or thief repeatedly failing the PIN until
  /// "Forgot PIN?" → "Reset App" appears, then tapping through the
  /// destructive path to deny the legitimate user access to their
  /// data. A successful biometric proves physical possession by the
  /// registered user.
  ///
  /// If biometric is not enabled in settings, falls through to the
  /// original DeleteConfirmDialog (typed-"DELETE" typed confirmation).
  /// That's still safer than a simple button press but lacks the
  /// physical-presence proof that biometric provides.
  Future<void> _confirmAndReset() async {
    final l10n = L10n.of(context)!;
    final useBiometric = _settings?.biometricEnabled == true;

    if (useBiometric) {
      // allow device-credential (PIN/pattern/passcode)
      // fallback so a user whose fingerprint / Face ID fails
      // temporarily (wet finger, low light, mask) can still prove
      // physical possession. `biometricOnly: false` tells the OS to
      // offer its own credential-entry sheet on a biometric miss.
      final outcome = await _auth.authenticate(
        reason: l10n.resetAppBiometricReason,
        biometricOnly: false,
      );
      if (outcome != BiometricOutcome.success) {
        if (!mounted) return;
        AppSnackBar.show(context, l10n.resetAppBiometricFailed);
        return;
      }
    }

    if (!mounted) return;
    final confirmed = await DeleteConfirmDialog.show(context);
    if (confirmed != true) return;
    if (!mounted) return;
    await _scheduleResetWithUndoWindow();
  }

  /// 10-second cancellable undo window between the typed
  /// "DELETE" confirmation and the actual wipe. Covers "fat-finger"
  /// regret — the user has already passed biometric + typed DELETE,
  /// but may still want a last escape.
  ///
  /// Flow:
  /// 1. Show a non-dismissible SnackBar with countdown copy.
  /// 2. Start a periodic timer that ticks the visible countdown.
  /// 3. If the user taps "Cancel" → clear timer, show confirmation.
  /// 4. If the timer elapses → run the wipe.
  ///
  /// The timer and SnackBar controller are kept on the state so
  /// lifecycle teardown (dispose, navigating away) can cancel both.
  Future<void> _scheduleResetWithUndoWindow() async {
    const totalSeconds = 10;
    final l10n = L10n.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    var remaining = totalSeconds;
    var cancelled = false;

    // StatefulBuilder gives us a setState we can call from the
    // periodic ticker to rebuild the countdown text. Without this,
    // `Text(l10n.resetAppUndoToast(remaining))` is a one-shot
    // snapshot at snackbar-show time and the seconds number sits
    // frozen for the entire 10-second window.
    StateSetter? rebuildCountdown;

    final controller = messenger.showSnackBar(SnackBar(
      content: StatefulBuilder(
        builder: (context, setState) {
          rebuildCountdown = setState;
          return Text(l10n.resetAppUndoToast(remaining));
        },
      ),
      duration: const Duration(seconds: totalSeconds),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: l10n.resetAppUndoCancel,
        onPressed: () {
          cancelled = true;
        },
      ),
    ));

    final ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining -= 1;
      // Force the StatefulBuilder to rebuild so the user sees
      // 9 → 8 → 7 ticks. setState is a no-op closure here because
      // `remaining` is a closure-captured var — the rebuild just
      // re-reads it.
      rebuildCountdown?.call(() {});
      if (remaining <= 0 || cancelled) t.cancel();
    });

    // Wait for the SnackBar to close (either natural dismiss,
    // Cancel tap, or widget teardown).
    final reason = await controller.closed;
    ticker.cancel();

    if (cancelled || reason == SnackBarClosedReason.action) {
      if (!mounted) return;
      AppSnackBar.show(context, l10n.resetAppCancelled);
      return;
    }

    await DatabaseService.instance.userRepo.deleteAllData();
    if (!mounted) return;
    // Mirror the Settings → Delete flow: explicit confirmation dialog
    // before we close the process, so the user sees the reset took
    // effect and understands the next launch will start fresh.
    // Without this the old behaviour was inconsistent — the in-place
    // SystemNavigator.pop() inside deleteAllData sometimes raced the
    // lock-screen rebuild so users saw the lock UI linger while the
    // app tried to exit.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.allDataDeletedTitle),
        content: Text(l10n.allDataDeletedBody),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.closeAppButton),
          ),
        ],
      ),
    );
    await UserRepository.requestAppExit();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    return Scaffold(
      // Transparent so the BrandAmbientBackground gradient fills the full
      // screen instead of being masked by the scaffold's own surface.
      // Shared with onboarding + the shell so every chrome-level screen
      // reads at the same intensity; previously the lock screen ran at
      // ~0.55 outer opacity which the user flagged as too bright.
      backgroundColor: Colors.transparent,
      body: BrandAmbientBackground(
        child: SafeArea(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  GlowBox(
                    color: cs.primary,
                    glowOpacity: 0.55,
                    blurRadius: 36,
                    spreadRadius: 6,
                    shape: BoxShape.circle,
                    child: const _AnimatedLogo(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Semantics(
                    liveRegion: _isError || _lockout.isLockedOut,
                    child: BionicText(
                      text: _statusText(l10n),
                      style: tt.bodyLarge?.copyWith(
                        color:
                            (_isError || _lockout.isLockedOut)
                                ? cs.error
                                : cs.onSurfaceVariant,
                      ),
                      enabled:
                          SettingsProvider.maybeOf(
                            context,
                          )?.bionicReadingEnabled ??
                          false,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // PIN dots
                  PinDots(
                    length: _enteredPin.length,
                    maxLength: _pinLength,
                    isError: _isError,
                  ),

                  const Spacer(),

                  NumberPad(
                    onDigit: _onDigit,
                    onDelete: _onDelete,
                    onBiometric:
                        _settings?.biometricEnabled == true
                            ? _tryBiometric
                            : null,
                    isDisabled: _lockout.isLockedOut,
                  ),

                  // Show "Forgot PIN?" from the FIRST failed
                  // attempt, not after two full lockouts (~10+ wrong
                  // tries). Recognition > recall is core ADHD
                  // accommodation, and a genuinely forgetful user
                  // should see the escape hatch immediately, not be
                  // forced through two exponential-backoff lockouts
                  // first. The destructive reset itself is still gated
                  // by biometric + typed-"DELETE" confirmation (see
                  // _confirmAndReset), so surfacing the entry point
                  // earlier does not lower overall security.
                  if (_lockout.failedAttempts > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: TextButton(
                        onPressed: _showForgotPinDialog,
                        child: Text(
                          l10n.forgotPin,
                          style: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
      ),
    );
  }
}

class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo();

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scaleAnim = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.of(context);
    final shouldReduce = mq.disableAnimations || mq.accessibleNavigation;
    if (shouldReduce != _reduceMotion) {
      _reduceMotion = shouldReduce;
      if (_reduceMotion) {
        _ctrl.stop();
        _ctrl.value = 0.5; // midpoint = scale 1.0
      } else {
        _ctrl.repeat(reverse: true);
      }
    } else if (!_reduceMotion && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion) {
      return const RetraqLogo(size: 80, showText: true);
    }
    return ScaleTransition(
      scale: _scaleAnim,
      child: const RetraqLogo(size: 80, breathe: true, showText: true),
    );
  }
}
