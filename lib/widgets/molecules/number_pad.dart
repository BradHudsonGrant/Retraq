import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_spacing.dart';

/// Reusable 3×4 number pad with optional biometric button.
/// Used by LockScreen and PIN setup dialog.
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.onBiometric,
    this.isDisabled = false,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onBiometric;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: isDisabled ? 'Number pad, disabled' : null,
      child: Opacity(
        opacity: isDisabled ? 0.3 : 1.0,
        child: IgnorePointer(
          ignoring: isDisabled,
          child: Column(
            children: [
              for (final row in [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:
                        row
                            .map(
                              (d) => PadButton(
                                label: '$d',
                                onTap: () => onDigit(d),
                              ),
                            )
                            .toList(),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (onBiometric != null)
                    PadButton(icon: Icons.fingerprint, onTap: onBiometric!)
                  else
                    const SizedBox(width: 72),
                  PadButton(label: '0', onTap: () => onDigit(0)),
                  PadButton(
                    icon: Icons.backspace_outlined,
                    onTap: onDelete,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single circular button on the number pad.
class PadButton extends StatelessWidget {
  const PadButton({
    super.key,
    this.label,
    this.icon,
    required this.onTap,
    this.color,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label:
          label ?? (icon == Icons.backspace_outlined ? 'Delete' : 'Biometric'),
      child: Material(
        color: cs.surfaceContainerLow,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child:
                  label != null
                      ? Text(
                        label!,
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color ?? cs.onSurface,
                        ),
                      )
                      : Icon(icon, size: 28, color: color ?? cs.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated row of PIN dot indicators.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.maxLength,
    this.isError = false,
  });

  final int length;
  final int maxLength;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      liveRegion: true,
      label: '$length of $maxLength digits entered${isError ? ', error' : ''}',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(maxLength, (i) {
          final filled = i < length;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isError
                        ? cs.error
                        : filled
                        ? cs.primary
                        : cs.surfaceContainerHigh,
                border: filled ? null : Border.all(color: cs.outlineVariant),
              ),
            ),
          );
        }),
      ),
    );
  }
}
