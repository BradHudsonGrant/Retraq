import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../l10n/app_localizations.dart';
import '../models/user_settings.dart';
import '../services/database_service.dart';
import '../services/lockout_controller.dart';
import '../services/secure_storage.dart';
import '../services/settings_repository.dart';
import '../providers/settings_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/atoms/animated_mesh_background.dart';
import '../widgets/atoms/bionic_text.dart';
import '../widgets/atoms/glow_box.dart';
import '../widgets/atoms/retraq_logo.dart';
import '../widgets/molecules/number_pad.dart';
import '../widgets/organisms/delete_confirm_dialog.dart';
import '../widgets/organisms/pin_setup_sheet.dart' show pinLengthPrefKey;

/// Full-screen lock that shows on app open when app lock is enabled.
/// Supports PIN entry, optional biometric unlock, and brute-force protection.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final SettingsRepository _settingsRepo = DatabaseService.instance.settings;
  final _auth = LocalAuthentication();

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
    try {
      final didAuth = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (didAuth && mounted) {
        widget.onUnlocked();
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric auth failed: $e');
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
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showDeleteConfirmation();
                },
                child: Text(l10n.resetApp, style: TextStyle(color: cs.error)),
              ),
            ],
          ),
    );
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await DeleteConfirmDialog.show(context);
    if (confirmed != true) return;
    await DatabaseService.instance.userRepo.deleteAllData();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Drifting mesh backdrop — adds depth without distracting from PIN.
          Positioned.fill(
            child: AnimatedMeshBackground(
              colors: [
                cs.primary.withValues(alpha: 0.35),
                cs.tertiary.withValues(alpha: 0.25),
                cs.secondaryContainer.withValues(alpha: 0.30),
              ],
              baseColor: cs.surface,
              opacity: 0.55,
            ),
          ),
          SafeArea(
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

                  if (_lockout.lockoutCount >= 2)
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
        ],
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
