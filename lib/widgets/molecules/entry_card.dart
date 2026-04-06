import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../atoms/retraq_card.dart';
import '../atoms/retraq_chip.dart';
import 'mood_selector.dart';

/// A journal entry preview card (used in "Previously…" and Recap detail).
/// Composed of RetraqCard + RetraqChip atoms.
class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.dateLabel,
    required this.text,
    this.title,
    this.mood,
    this.color,
    this.chipColor,
    this.chipTextColor,
    this.onTap,
    this.onMenuTap,
  });

  final String dateLabel;
  final String text;
  final String? title;
  final int? mood;
  final Color? color;
  final Color? chipColor;
  final Color? chipTextColor;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: 'Journal entry for $dateLabel',
      child: RetraqCard(
        color: color,
        elevation: color == null ? 1 : 0,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RetraqChip(
                    label: dateLabel,
                    color: chipColor,
                    textColor: chipTextColor,
                  ),
                  IconButton(
                    onPressed: onMenuTap,
                    tooltip: 'Entry options',
                    icon: Icon(
                      Icons.more_horiz,
                      color: Theme.of(context).colorScheme.onSurfaceVariant
                          .withValues(alpha: onMenuTap != null ? 0.6 : 0.3),
                    ),
                  ),
                ],
              ),
              if (mood != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(
                      moodEmoji(mood!),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      moodLabel(mood!),
                      style: tt.labelMedium?.copyWith(
                        color: moodColor(mood!),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (title != null && title!.isNotEmpty) ...[
                Text(
                  title!,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(text, style: tt.bodyLarge?.copyWith(height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}
