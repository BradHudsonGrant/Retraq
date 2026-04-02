import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/pin_service.dart';
import '../../theme/app_spacing.dart';
import '../molecules/number_pad.dart';

/// Bottom-sheet widget that verifies the current PIN before disabling app lock.
class PinVerifySheet extends StatefulWidget {
  const PinVerifySheet({super.key, required this.pinHash});

  final String pinHash;

  @override
  State<PinVerifySheet> createState() => _PinVerifySheetState();
}

class _PinVerifySheetState extends State<PinVerifySheet> {
  String _entered = '';
  bool _isError = false;
  bool _isVerifying = false;
  bool _isLockedOut = false;
  int _failedAttempts = 0;
  int _lockoutCount = 0;
  Timer? _lockoutTimer;
  int _lockoutSecondsLeft = 0;

  static const _pinLength = 4;
  static const _maxAttempts = 5;
  static const _maxLockoutSeconds = 300; // 5 minutes cap

  // Same SharedPreferences keys as LockScreen for consistent behavior.
  static const _prefFailedAttempts = 'lock_failed_attempts';
  static const _prefLockoutCount = 'lock_lockout_count';
  static const _prefLockoutEnd = 'lock_lockout_end';

  @override
  void initState() {
    super.initState();
    _loadLockoutState();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLockoutState() async {
    final prefs = await SharedPreferences.getInstance();
    _failedAttempts = prefs.getInt(_prefFailedAttempts) ?? 0;
    _lockoutCount = prefs.getInt(_prefLockoutCount) ?? 0;
    final lockoutEndMs = prefs.getInt(_prefLockoutEnd) ?? 0;
    if (lockoutEndMs > 0) {
      final lockoutEnd = DateTime.fromMillisecondsSinceEpoch(lockoutEndMs);
      final remaining = lockoutEnd.difference(DateTime.now()).inSeconds;
      if (remaining > 0) {
        _lockoutSecondsLeft = remaining;
        if (mounted) setState(() => _isLockedOut = true);
        _startLockoutCountdown();
      } else {
        _clearPersistedLockout();
      }
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

  Future<void> _onDigit(int digit) async {
    if (_isVerifying || _isLockedOut || _entered.length >= _pinLength) return;
    setState(() {
      _entered += '$digit';
      _isError = false;
    });
    if (_entered.length == _pinLength) {
      _verify();
    }
  }

  void _onDelete() {
    if (_isVerifying || _isLockedOut || _entered.isEmpty) return;
    setState(() {
      _entered = _entered.substring(0, _entered.length - 1);
      _isError = false;
    });
  }

  Future<void> _verify() async {
    setState(() => _isVerifying = true);
    final ok = await PinService.verifyPin(_entered, widget.pinHash);
    if (!mounted) return;
    if (ok) {
      _clearPersistedLockout();
      Navigator.pop(context, true);
    } else {
      _failedAttempts++;
      setState(() {
        _isError = true;
        _isVerifying = false;
        _entered = '';
      });
      HapticFeedback.heavyImpact();

      if (_failedAttempts >= _maxAttempts) {
        _startLockout();
      }
    }
  }

  String get _statusText {
    if (_isLockedOut) return 'Too many attempts. Wait ${_lockoutSecondsLeft}s.';
    if (_isError) {
      final remaining = _maxAttempts - _failedAttempts;
      return 'Incorrect PIN. $remaining ${remaining == 1 ? 'attempt' : 'attempts'} remaining.';
    }
    return 'Enter your PIN to disable app lock';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            liveRegion: _isError || _isLockedOut,
            child: Text(
              _statusText,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: (_isError || _isLockedOut) ? cs.error : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PinDots(
            length: _entered.length,
            maxLength: _pinLength,
            isError: _isError,
          ),
          const SizedBox(height: AppSpacing.xl),
          NumberPad(
            onDigit: (d) => _onDigit(d),
            onDelete: _onDelete,
            isDisabled: _isVerifying || _isLockedOut,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
