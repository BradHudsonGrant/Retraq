import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/journal_entry.dart';
import '../../providers/settings_provider.dart';
import '../../services/export_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/entry_action_dialogs.dart';
import '../atoms/bionic_text.dart';
import '../atoms/retraq_chip.dart';
import '../molecules/entry_action_menu.dart';
import '../molecules/mood_selector.dart';

/// Displays journal entries for a single date below the calendar grid.
/// Shows one date divider, then each entry as a full-width card.
class EntryDetailView extends StatelessWidget {
  const EntryDetailView({
    super.key,
    required this.entries,
    required this.date,
  });

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
        // ── Date divider (once) ──
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(child: Divider(color: cs.outlineVariant)),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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

        // ── Entry cards ──
        ...entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _EntryCard(entry: entry),
            )),

        // ── Share day ──
        if (entries.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: OutlinedButton.icon(
                onPressed: () =>
                    ExportService.instance.shareDayEntries(entries, date),
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

    final timeLabel = DateFormat('h:mm a').format(entry.createdAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp + label + actions
          Row(
            children: [
              Text(
                timeLabel,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                  letterSpacing: 0.5,
                ),
              ),
              if (entry.label != null) ...[
                const SizedBox(width: AppSpacing.sm),
                RetraqChip(
                  label: entry.label!,
                  color: entry.label == 'AM'
                      ? cs.primaryContainer
                      : cs.tertiaryContainer,
                  textColor: entry.label == 'AM'
                      ? cs.onPrimaryContainer
                      : cs.onTertiaryContainer,
                ),
              ],
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
                Text(moodEmoji(entry.mood!), style: const TextStyle(fontSize: 16)),
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
              enabled: SettingsProvider.maybeOf(context)?.bionicReadingEnabled ?? false,
            ),
        ],
      ),
    );
  }
}
