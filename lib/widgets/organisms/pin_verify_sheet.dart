import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../services/lockout_controller.dart';
import '../../services/pin_service.dart';
import '../../services/secure_storage.dart';
import 'pin_setup_sheet.dart' show pinLengthPrefKey;
import '../../theme/app_spacing.dart';
import '../atoms/drag_handle.dart';
import '../molecules/number_pad.dart';

/// Bottom-sheet widget that verifies the current PIN before disabling app lock.
class PinVerifySheet extends StatefulWidget {
  const PinVerifySheet({super.key, required this.pinHash});

  final String pinHash;

  @override
  State<PinVerifySheet> createState() => _PinVerifySheetState();
}

class _PinVerifySheetState extends State<PinVerifySheet> {
  late final LockoutController _lockout;

  String _entered = '';
  bool _isError = false;
  bool _isVerifying = false;

  int _pinLength = 4;

  @override
  void initState() {
    super.initState();
    _lockout = LockoutController();
    _lockout.addListener(() {
      if (mounted) setState(() {});
    });
    _loadState();
  }

  @override
  void dispose() {
    _lockout.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    // Read configured PIN length (4 or 6, default 4) from secure storage.
    final storedPinLength =
        int.tryParse(
          await hardenedSecureStorage.read(key: pinLengthPrefKey) ?? '',
        ) ??
        4;
    if (mounted) {
      setState(() => _pinLength = (storedPinLength == 6) ? 6 : 4);
    }

    await _lockout.loadState();
  }

  Future<void> _onDigit(int digit) async {
    if (_isVerifying || _lockout.isLockedOut || _entered.length >= _pinLength) {
      return;
    }
    setState(() {
      _entered += '$digit';
      _isError = false;
    });
    if (_entered.length == _pinLength) {
      _verify();
    }
  }

  void _onDelete() {
    if (_isVerifying || _lockout.isLockedOut || _entered.isEmpty) return;
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
      _lockout.clearLockout();
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isError = true;
        _isVerifying = false;
        _entered = '';
      });
      HapticFeedback.heavyImpact();
      _lockout.recordFailedAttempt();
    }
  }

  String _statusText(L10n l10n) {
    if (_lockout.isLockedOut) {
      return l10n.lockoutMessage(_lockout.lockoutSecondsLeft);
    }
    if (_lockout.failedAttempts > 0) {
      final remaining = LockoutController.maxAttempts - _lockout.failedAttempts;
      return l10n.wrongPinMessage(remaining);
    }
    return l10n.enterPin;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

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
          const DragHandle(),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            liveRegion: _isError || _lockout.isLockedOut,
            child: Text(
              _statusText(l10n),
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: (_isError || _lockout.isLockedOut) ? cs.error : null,
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
            isDisabled: _isVerifying || _lockout.isLockedOut,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
