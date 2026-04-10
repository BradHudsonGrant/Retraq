import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../utils/test_keys.dart';
import '../atoms/glow_box.dart';
import '../atoms/mood_blob.dart';
import '../atoms/particle_burst.dart';

// Re-export mood utilities for backwards compatibility
export '../../utils/mood_utils.dart';

/// Mood levels from 1 (Rough) to 5 (Amazing).
/// Each has a blob emoji and label; color is resolved from the theme.
class MoodOption {
  final int value;
  final String emoji;
  final String label;

  const MoodOption(this.value, this.emoji, this.label);
}

const _moodOptions = [
  MoodOption(1, '\u{1F622}', 'Rough'),
  MoodOption(2, '\u{1F614}', 'Low'),
  MoodOption(3, '\u{1F610}', 'Neutral'),
  MoodOption(4, '\u{1F60A}', 'Good'),
  MoodOption(5, '\u{1F929}', 'Amazing'),
];

/// Returns the mood color list appropriate for the current brightness.
List<Color> _moodColors(Brightness brightness) =>
    AppColors.moodColors(brightness);

/// A row of 5 tappable mood options with blob emojis and teal-scale colors.
/// Selected mood shows a colored ring and label; unselected are dimmed.
class MoodSelector extends StatelessWidget {
  final int? selectedMood;
  final ValueChanged<int?> onChanged;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _moodColors(theme.brightness);

    return Semantics(
      label: 'Mood selector',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            _moodOptions.map((option) {
              final isSelected = selectedMood == option.value;
              final color = colors[option.value - 1];
              return _MoodButton(
                key: TestKeys.moodOption(option.value),
                option: option,
                color: color,
                isSelected: isSelected,
                hasSelection: selectedMood != null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Tap again to deselect
                  onChanged(isSelected ? null : option.value);
                },
                theme: theme,
              );
            }).toList(),
      ),
    );
  }
}

class _MoodButton extends StatefulWidget {
  final MoodOption option;
  final Color color;
  final bool isSelected;
  final bool hasSelection;
  final VoidCallback onTap;
  final ThemeData theme;

  const _MoodButton({
    super.key,
    required this.option,
    required this.color,
    required this.isSelected,
    required this.hasSelection,
    required this.onTap,
    required this.theme,
  });

  @override
  State<_MoodButton> createState() => _MoodButtonState();
}

class _MoodButtonState extends State<_MoodButton> {
  final GlobalKey<ParticleBurstState> _burstKey =
      GlobalKey<ParticleBurstState>();

  void _handleTap() {
    widget.onTap();
    // Fire the celebratory particle burst on the SELECTING tap, not on
    // deselect. (When the button is currently selected, the user is removing
    // the choice — bursting feels celebratory in the wrong direction.)
    if (!widget.isSelected) {
      _burstKey.currentState?.fire();
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.hasSelection && !widget.isSelected ? 0.4 : 1.0;
    final reduceMotion = AppMotion.reduce(context);
    final animDuration = reduceMotion ? Duration.zero : AppMotion.fast;

    // The pre-existing AnimatedContainer ring — UNCHANGED so the
    // mood_selector_test.dart decoration assertions still hold.
    final ring = AnimatedContainer(
      duration: animDuration,
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            widget.isSelected
                ? Border.all(color: widget.color, width: 2.5)
                : null,
        color:
            widget.isSelected
                ? widget.color.withValues(alpha: 0.12)
                : Colors.transparent,
      ),
      child: Center(
        child: MoodBlob(
          mood: widget.option.value,
          size: 28,
          color: widget.color,
          isSelected: widget.isSelected,
        ),
      ),
    );

    // Sibling glow halo — does NOT modify ring.decoration so existing widget
    // tests assertions on the ring's decoration still pass.
    Widget ringStack = SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1) Glow halo behind the ring (only when selected)
          if (widget.isSelected)
            IgnorePointer(
              child: GlowBox(
                color: widget.color,
                glowOpacity: 0.6,
                blurRadius: 26,
                spreadRadius: 4,
                shape: BoxShape.circle,
                child: const SizedBox(width: 48, height: 48),
              ),
            ),

          // 2) The ring itself
          ring,

          // 3) Particle burst overlay (one-shot, fires on selection tap)
          IgnorePointer(
            child: ParticleBurst(
              key: _burstKey,
              colors: [
                widget.color,
                widget.color.withValues(alpha: 0.7),
                Colors.white,
              ],
              count: 8,
              duration: const Duration(milliseconds: 600),
              minDistance: 22,
              maxDistance: 56,
              minRadius: 1.5,
              maxRadius: 3.5,
              gravity: 30,
            ),
          ),
        ],
      ),
    );

    // Spring scale-up on selection.
    if (!reduceMotion) {
      ringStack = ringStack
          .animate(target: widget.isSelected ? 1 : 0)
          .scaleXY(
            begin: 1.0,
            end: 1.08,
            duration: 280.ms,
            curve: AppMotion.springSmooth,
          );
    }

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: '${widget.option.label} mood',
      child: InkWell(
        onTap: _handleTap,
        borderRadius: AppSpacing.borderRadiusFull,
        child: AnimatedOpacity(
          opacity: opacity,
          duration: animDuration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ringStack,
              const SizedBox(height: AppSpacing.xs),
              AnimatedDefaultTextStyle(
                duration: animDuration,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  color:
                      widget.isSelected
                          ? widget.color
                          : widget.theme.colorScheme.onSurfaceVariant,
                ),
                child: Text(widget.option.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
