import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/journal_entry.dart';
import '../../widgets/settings_provider.dart';
import '../../services/export_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/entry_action_dialogs.dart';
import '../atoms/bionic_text.dart';
import '../atoms/mood_blob.dart';
import '../atoms/retraq_card.dart';
import '../atoms/retraq_chip.dart';
import '../molecules/entry_action_menu.dart';
import '../molecules/mood_selector.dart';

/// Displays journal entries for a single date below the calendar grid.
/// Shows one date divider, then each entry as a full-width card.
class EntryDetailView extends StatelessWidget {
  const EntryDetailView({super.key, required this.entries, required this.date});

  final List<JournalEntry> entries;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateLabel = DateFormat('MMMM d, EEEE').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(child: Divider(color: cs.outlineVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  dateLabel.toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: Divider(color: cs.outlineVariant)),
            ],
          ),
        ),

        ...entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _EntryCard(entry: entry),
          ),
        ),

        if (entries.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: OutlinedButton.icon(
                onPressed:
                    () => ExportService.instance.shareDayEntries(entries, date),
                icon: const Icon(Icons.share_outlined, size: 16),
                label: const Text('Share Day'),
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final JournalEntry entry;

  Future<void> _confirmEdit(BuildContext context) async {
    await confirmAndEditEntry(context, entry);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    await confirmAndDeleteEntry(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Show a wall-clock time only when the entry has no AM/PM bucket label;
    // the chip already communicates "when" for labelled entries.
    final hasLabel = entry.label != null;
    final timeLabel =
        hasLabel ? null : DateFormat('h:mm a').format(entry.createdAt);
    // Backdated marker: if the entry was written on a different calendar day
    // from the day it's about, show the creation date so "12:34 AM" doesn't
    // look adjacent to other entries that share the displayed card day.
    final createdDate = DateTime(
      entry.createdAt.year,
      entry.createdAt.month,
      entry.createdAt.day,
    );
    final entryDate = DateTime(
      entry.date.year,
      entry.date.month,
      entry.date.day,
    );
    final isBackdated = createdDate != entryDate;
    final backdatedLabel =
        isBackdated ? DateFormat('MMM d').format(entry.createdAt) : null;

    return SizedBox(
      width: double.infinity,
      // Shared content-card tier: raised surfaceContainerHigh fill +
      // 1px outlineVariant outline to match RecentDayCard, day cards,
      // and the rest of the minimal-border card system.
      child: RetraqCard(
        color: cs.surfaceContainerHigh,
        outlined: true,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp + label + actions
          Row(
            children: [
              if (timeLabel != null)
                Text(
                  backdatedLabel != null
                      ? '$backdatedLabel · $timeLabel'
                      : timeLabel,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                    letterSpacing: 0.5,
                    fontStyle: isBackdated ? FontStyle.italic : null,
                  ),
                ),
              if (hasLabel && backdatedLabel != null) ...[
                Text(
                  '$backdatedLabel · ',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                    letterSpacing: 0.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (hasLabel)
                RetraqChip(
                  label: entry.label!,
                  color:
                      entry.label == 'AM'
                          ? cs.primaryContainer
                          : cs.tertiaryContainer,
                  textColor:
                      entry.label == 'AM'
                          ? cs.onPrimaryContainer
                          : cs.onTertiaryContainer,
                ),
              const Spacer(),
              EntryActionMenu(
                entry: entry,
                onEdit: () => _confirmEdit(context),
                onDelete: () => _confirmDelete(context),
              ),
            ],
          ),
          // Mood indicator
          if (entry.mood != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                MoodBlob(
                  mood: entry.mood!,
                  size: 20,
                  color: moodColorFor(
                    entry.mood!,
                    Theme.of(context).brightness,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  moodLabel(entry.mood!),
                  style: tt.labelMedium?.copyWith(
                    color: moodColor(entry.mood!),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),

          // Entry text
          if (entry.entry != null && entry.entry!.isNotEmpty)
            BionicText(
              text: entry.entry!,
              style: tt.bodyLarge?.copyWith(height: 1.6),
              enabled:
                  SettingsProvider.maybeOf(context)?.bionicReadingEnabled ??
                  false,
            ),
        ],
      ),
      ),
    );
  }
}
