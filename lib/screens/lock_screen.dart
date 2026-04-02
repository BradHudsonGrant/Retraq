import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';
import '../services/database_service.dart';
import '../services/settings_repository.dart';
import '../theme/app_spacing.dart';
import '../widgets/atoms/sincethen_logo.dart';
import '../widgets/molecules/number_pad.dart';

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

  String _enteredPin = '';
  bool _isError = false;
  bool _isLockedOut = false;
  int _failedAttempts = 0;
  int _lockoutCount = 0; // how many times lockout has triggered
  UserSettings? _settings;
  Timer? _lockoutTimer;
  int _lockoutSecondsLeft = 0;

  static const _maxAttempts = 5;
  static const _maxLockoutSeconds = 300; // 5 minutes cap

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  static const _prefFailedAttempts = 'lock_failed_attempts';
  static const _prefLockoutCount = 'lock_lockout_count';
  static const _prefLockoutEnd = 'lock_lockout_end';

  Future<void> _loadSettings() async {
    final s = await _settingsRepo.getSettings();
    if (!mounted) return;
    setState(() => _settings = s);

    final prefs = await SharedPreferences.getInstance();
    _failedAttempts = prefs.getInt(_prefFailedAttempts) ?? 0;
    _lockoutCount = prefs.getInt(_prefLockoutCount) ?? 0;
    final lockoutEndMs = prefs.getInt(_prefLockoutEnd) ?? 0;
    if (lockoutEndMs > 0) {
      final lockoutEnd = DateTime.fromMillisecondsSinceEpoch(lockoutEndMs);
      final remaining = lockoutEnd.difference(DateTime.now()).inSeconds;
      if (remaining > 0) {
        _lockoutSecondsLeft = remaining;
        setState(() => _isLockedOut = true);
        _startLockoutCountdown();
      } else {
        _clearPersistedLockout();
      }
    }

    if (s.appLockEnabled && s.biometricEnabled) {
      _tryBiometric();
    }
  }

  Future<void> _persistLockout(DateTime lockoutEnd) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefFailedAttempts, _failedAttempts);
    await prefs.setInt(_prefLockoutCount, _lockoutCount);
    await prefs.setInt(_prefLockoutEnd, lockoutEnd.millisecondsSinceEpoch);
  }

  Future<void> _clearPersistedLockout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefFailedAttempts);
    await prefs.remove(_prefLockoutCount);
    await prefs.remove(_prefLockoutEnd);
  }

  Future<void> _tryBiometric() async {
    if (_isLockedOut) return;
    try {
      final didAuth = await _auth.authenticate(
        localizedReason: 'Unlock SinceThen',
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

  static const _pinLength = 4;

  void _onDigit(int digit) {
    if (_settings == null || _isLockedOut || _isVerifying || _enteredPin.length >= _pinLength) return;
    setState(() {
      _isError = false;
      _enteredPin += '$digit';
    });

    if (_enteredPin.length == _pinLength) {
      _verifyPin();
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty || _isLockedOut) return;
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
      _clearPersistedLockout();
      widget.onUnlocked();
    } else {
      _failedAttempts++;
      setState(() {
        _isError = true;
        _enteredPin = '';
      });
      HapticFeedback.heavyImpact();

      if (_failedAttempts >= _maxAttempts) {
        _startLockout();
      }
    }
  }

  Duration get _lockoutDuration {
    // Exponential backoff: 30s, 60s, 120s, 240s, capped at 300s
    final seconds = (30 * (1 << _lockoutCount)).clamp(30, _maxLockoutSeconds);
    return Duration(seconds: seconds);
  }

  void _startLockout() {
    final duration = _lockoutDuration;
    _lockoutCount++;
    _lockoutSecondsLeft = duration.inSeconds;
    setState(() => _isLockedOut = true);
    final lockoutEnd = DateTime.now().add(duration);
    _persistLockout(lockoutEnd);
    _startLockoutCountdown();
  }

  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _lockoutSecondsLeft--;
      if (_lockoutSecondsLeft <= 0) {
        timer.cancel();
        _clearPersistedLockout();
        setState(() {
          _isLockedOut = false;
          _failedAttempts = 0;
        });
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  String get _statusText {
    if (_isLockedOut) return 'Too many attempts. Wait ${_lockoutSecondsLeft}s.';
    if (_isError) {
      final remaining = _maxAttempts - _failedAttempts;
      return 'Wrong PIN. $remaining ${remaining == 1 ? 'attempt' : 'attempts'} remaining.';
    }
    return 'Enter your PIN';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            children: [
              const Spacer(flex: 2),

              const _AnimatedLogo(),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: _isError || _isLockedOut,
                child: Text(
                  _statusText,
                  style: tt.bodyLarge?.copyWith(
                    color: (_isError || _isLockedOut)
                        ? cs.error
                        : cs.onSurfaceVariant,
                  ),
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
                onBiometric: _settings?.biometricEnabled == true
                    ? _tryBiometric
                    : null,
                isDisabled: _isLockedOut,
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
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

class _AnimatedLogoState extends State<_AnimatedLogo> with SingleTickerProviderStateMixin {
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

    _scaleAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
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
      return const SinceThenLogo(size: 80, showText: true);
    }
    return ScaleTransition(
      scale: _scaleAnim,
      child: const SinceThenLogo(size: 80, breathe: true, showText: true),
    );
  }
}

