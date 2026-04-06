import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../atoms/mood_blob.dart';

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
        children: _moodOptions.map((option) {
          final isSelected = selectedMood == option.value;
          final color = colors[option.value - 1];
          return _MoodButton(
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

class _MoodButton extends StatelessWidget {
  final MoodOption option;
  final Color color;
  final bool isSelected;
  final bool hasSelection;
  final VoidCallback onTap;
  final ThemeData theme;

  const _MoodButton({
    required this.option,
    required this.color,
    required this.isSelected,
    required this.hasSelection,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = hasSelection && !isSelected ? 0.4 : 1.0;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animDuration = reduceMotion ? Duration.zero : const Duration(milliseconds: 150);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${option.label} mood',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusFull,
        child: AnimatedOpacity(
          opacity: opacity,
          duration: animDuration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: animDuration,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: color, width: 2.5)
                      : null,
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
                child: Center(
                  child: MoodBlob(
                    mood: option.value,
                    size: 28,
                    color: color,
                    isSelected: isSelected,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AnimatedDefaultTextStyle(
                duration: animDuration,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? color
                      : theme.colorScheme.onSurfaceVariant,
                ),
                child: Text(option.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

