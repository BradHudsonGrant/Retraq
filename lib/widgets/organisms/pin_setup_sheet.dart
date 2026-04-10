import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/secure_storage.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../molecules/number_pad.dart';

/// Secure storage key for the configured PIN length (4 or 6).
const pinLengthPrefKey = 'pin_length';

class PinSetupSheet extends StatefulWidget {
  const PinSetupSheet({super.key});

  @override
  State<PinSetupSheet> createState() => PinSetupSheetState();
}

class PinSetupSheetState extends State<PinSetupSheet> {
  String _enteredPin = '';
  String _firstPin = '';
  bool _isConfirmStep = false;
  bool _isError = false;

  int _pinLength = 4;
  Timer? _advanceTimer;
  bool _isDenylisted = false;

  static const _denylist4 = {
    '0000',
    '1111',
    '2222',
    '3333',
    '4444',
    '5555',
    '6666',
    '7777',
    '8888',
    '9999',
    '1234',
    '4321',
    '1230',
    '0123',
    '2580',
  };

  static const _denylist6 = {
    '000000',
    '111111',
    '222222',
    '333333',
    '444444',
    '555555',
    '666666',
    '777777',
    '888888',
    '999999',
    '123456',
    '654321',
    '012345',
  };

  Set<String> get _denylist => _pinLength == 6 ? _denylist6 : _denylist4;

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  void _onDigit(int digit) {
    if (_enteredPin.length >= _pinLength) return;
    setState(() {
      _isError = false;
      _isDenylisted = false;
      _enteredPin += '$digit';
    });

    // Auto-advance when all digits entered.
    if (_enteredPin.length == _pinLength) {
      _advanceTimer?.cancel();
      _advanceTimer = Timer(const Duration(milliseconds: 200), _advance);
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _isError = false;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _advance() async {
    if (_enteredPin.length < _pinLength) return;

    if (!_isConfirmStep) {
      if (_denylist.contains(_enteredPin)) {
        HapticFeedback.heavyImpact();
        setState(() {
          _isDenylisted = true;
          _enteredPin = '';
        });
        return;
      }
      // Move to confirm step
      setState(() {
        _isDenylisted = false;
        _firstPin = _enteredPin;
        _enteredPin = '';
        _isConfirmStep = true;
      });
    } else {
      // Verify match
      if (_enteredPin == _firstPin) {
        // Persist the chosen PIN length to secure storage for lock/verify screens.
        await hardenedSecureStorage.write(
          key: pinLengthPrefKey,
          value: '$_pinLength',
        );
        if (!mounted) return;
        Navigator.of(context).pop(_firstPin);
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _isError = true;
          _enteredPin = '';
        });
      }
    }
  }

  String get _title => _isConfirmStep ? 'Confirm PIN' : 'Set a PIN';

  String get _subtitle {
    if (_isDenylisted) return 'Too easy to guess. Choose a different PIN.';
    if (_isError) return 'PINs did not match. Try again.';
    return _isConfirmStep
        ? 'Enter the same PIN again'
        : 'Choose a $_pinLength-digit PIN';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),

            Animate(
              effects: [
                FadeEffect(duration: 360.ms, curve: Curves.easeOut),
                SlideEffect(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                  duration: 400.ms,
                  curve: AppMotion.emphasizedDecelerate,
                ),
              ],
              child: Text(
                _title,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              liveRegion: true,
              child: Animate(
                effects: [
                  FadeEffect(
                    delay: 80.ms,
                    duration: 360.ms,
                    curve: Curves.easeOut,
                  ),
                ],
                child: Text(
                  _subtitle,
                  style: tt.bodyMedium?.copyWith(
                    color:
                        (_isError || _isDenylisted)
                            ? cs.error
                            : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            // PIN length selector -- only shown during initial entry.
            if (!_isConfirmStep) ...[
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 4, label: Text('4 digits')),
                  ButtonSegment(value: 6, label: Text('6 digits')),
                ],
                selected: {_pinLength},
                onSelectionChanged: (v) {
                  setState(() {
                    _pinLength = v.first;
                    _enteredPin = '';
                    _isError = false;
                    _isDenylisted = false;
                  });
                },
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // PIN dots
            PinDots(
              length: _enteredPin.length,
              maxLength: _pinLength,
              isError: _isError,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Number pad
            NumberPad(onDigit: _onDigit, onDelete: _onDelete),

            const SizedBox(height: AppSpacing.md),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                if (_enteredPin.length >= _pinLength)
                  FilledButton(
                    onPressed: _advance,
                    child: Text(_isConfirmStep ? 'Set PIN' : 'Next'),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
