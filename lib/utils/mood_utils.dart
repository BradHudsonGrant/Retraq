import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Get the label for a mood value (1-5).
String moodLabel(int mood) {
  const labels = ['Rough', 'Low', 'Neutral', 'Good', 'Amazing'];
  if (mood < 1 || mood > 5) return '';
  return labels[mood - 1];
}

/// Get the color for a mood value (1-5), using light palette by default.
Color moodColor(int mood) {
  if (mood < 1 || mood > 5) return Colors.grey;
  return AppColors.moodColorsLight[mood - 1];
}

/// Get the color for a mood value (1-5) adapted to the given [brightness].
Color moodColorFor(int mood, Brightness brightness) {
  if (mood < 1 || mood > 5) return Colors.grey;
  return AppColors.moodColors(brightness)[mood - 1];
}

/// Get the emoji for a mood value (1-5).
String moodEmoji(int mood) {
  const emojis = ['\u{1F622}', '\u{1F614}', '\u{1F610}', '\u{1F60A}', '\u{1F929}'];
  if (mood < 1 || mood > 5) return '';
  return emojis[mood - 1];
}
