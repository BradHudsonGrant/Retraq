import 'package:flutter/material.dart';
import '../../models/journal_entry.dart';
import '../../theme/app_spacing.dart';
import '../../utils/entry_action_dialogs.dart';
import '../../widgets/molecules/entry_action_menu.dart';

/// Compact card showing a recent day's entries on the home screen.
class RecentDayCard extends StatelessWidget {
  const RecentDayCard({
    super.key,
    required this.label,
    required this.entries,
  });

  final String label;
  final List<JournalEntry> entries;

  Future<void> _confirmEdit(BuildContext context, JournalEntry entry) async {
    await confirmAndEditEntry(context, entry);
  }

  Future<void> _confirmDelete(BuildContext context, JournalEntry entry) async {
    await confirmAndDeleteEntry(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final entryPreview = entries.isNotEmpty
        ? entries.first.displayText.length > 60
            ? '${entries.first.displayText.substring(0, 60)}...'
            : entries.first.displayText
        : '';

    return Semantics(
      container: true,
      label: 'Entry for $label: $entryPreview',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(child: Icon(Icons.history, size: 14, color: cs.primary)),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < entries.length && i < 2; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entries[i].label != null)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: Text(
                        entries[i].label!,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      entries[i].displayText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  EntryActionMenu(
                    entry: entries[i],
                    onEdit: () => _confirmEdit(context, entries[i]),
                    onDelete: () => _confirmDelete(context, entries[i]),
                    iconSize: 18,
                    iconAlpha: 0.4,
                  ),
                ],
              ),
            ],
            if (entries.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  '+${entries.length - 2} more',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
