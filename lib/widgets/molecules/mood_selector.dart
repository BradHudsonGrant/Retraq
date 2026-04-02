import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// Mood levels from 1 (Rough) to 5 (Amazing).
/// Each has a blob emoji, label, and teal-scale color.
class MoodOption {
  final int value;
  final String emoji;
  final String label;
  final Color color;

  const MoodOption(this.value, this.emoji, this.label, this.color);
}

const _moodOptions = [
  MoodOption(1, '\u{1F622}', 'Rough', Color(0xFF80CBC4)), // teal 200
  MoodOption(2, '\u{1F614}', 'Low', Color(0xFF4DB6AC)),   // teal 300
  MoodOption(3, '\u{1F610}', 'Neutral', Color(0xFF26A69A)), // teal 400
  MoodOption(4, '\u{1F60A}', 'Good', Color(0xFF009688)),   // teal 500
  MoodOption(5, '\u{1F929}', 'Amazing', Color(0xFF00796B)), // teal 700
];

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

    return Semantics(
      label: 'Mood selector',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _moodOptions.map((option) {
          final isSelected = selectedMood == option.value;
          return _MoodButton(
            option: option,
            isSelected: isSelected,
            hasSelection: selectedMood != null,
            onTap: () {
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
  final bool isSelected;
  final bool hasSelection;
  final VoidCallback onTap;
  final ThemeData theme;

  const _MoodButton({
    required this.option,
    required this.isSelected,
    required this.hasSelection,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = hasSelection && !isSelected ? 0.4 : 1.0;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${option.label} mood',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusFull,
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 150),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: option.color, width: 2.5)
                      : null,
                  color: isSelected
                      ? option.color.withAlpha(30)
                      : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    option.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? option.color
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

/// Get the label for a mood value (1-5).
String moodLabel(int mood) {
  if (mood < 1 || mood > 5) return '';
  return _moodOptions[mood - 1].label;
}

/// Get the color for a mood value (1-5).
Color moodColor(int mood) {
  if (mood < 1 || mood > 5) return Colors.grey;
  return _moodOptions[mood - 1].color;
}

/// Get the emoji for a mood value (1-5).
String moodEmoji(int mood) {
  if (mood < 1 || mood > 5) return '';
  return _moodOptions[mood - 1].emoji;
}
