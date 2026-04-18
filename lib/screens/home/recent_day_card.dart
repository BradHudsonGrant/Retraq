import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import '../../models/journal_entry.dart';
import '../../widgets/settings_provider.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../utils/entry_action_dialogs.dart';
import '../../widgets/atoms/bionic_text.dart';
import '../../widgets/atoms/retraq_chip.dart';
import '../../widgets/molecules/entry_action_menu.dart';

/// Compact card showing a recent day's entries on the home screen.
///
/// When a day has more than 2 entries the card collapses to the oldest
/// 2 with a "+N more" affordance. Tapping that affordance expands the
/// card to show every entry for the day; tapping "Show less" collapses
/// it again. Preserved as state inside the card so expansion survives
/// parent rebuilds that happen as other streams emit.
class RecentDayCard extends StatefulWidget {
  const RecentDayCard({super.key, required this.label, required this.entries});

  final String label;
  final List<JournalEntry> entries;

  @override
  State<RecentDayCard> createState() => _RecentDayCardState();
}

class _RecentDayCardState extends State<RecentDayCard> {
  bool _expanded = false;

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
    final l10n = L10n.of(context)!;
    final reduceMotion = AppMotion.reduce(context);

    // Always render oldest-first so this card matches the Recap week/month
    // views — reading top-to-bottom gives a chronological story of the day.
    final sortedEntries = [...widget.entries]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final entryPreview = sortedEntries.isNotEmpty
        ? sortedEntries.first.displayText.length > 60
            ? '${sortedEntries.first.displayText.substring(0, 60)}...'
            : sortedEntries.first.displayText
        : '';

    final hasMore = sortedEntries.length > 2;
    final visibleCount =
        (_expanded || !hasMore) ? sortedEntries.length : 2;

    final card = Semantics(
      container: true,
      label: l10n.entryForDayPreview(widget.label, entryPreview),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: AppSpacing.borderRadiusXl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(Icons.history, size: 16, color: cs.primary),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  widget.label,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${sortedEntries.length} ${sortedEntries.length == 1 ? 'entry' : 'entries'}',
                  style: tt.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < sortedEntries.length && i < visibleCount; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label pill + action row
                  Row(
                    children: [
                      if (sortedEntries[i].label != null)
                        RetraqChip(
                          label: sortedEntries[i].label!,
                          color: sortedEntries[i].label == 'AM'
                              ? cs.primaryContainer
                              : cs.tertiaryContainer,
                          textColor: sortedEntries[i].label == 'AM'
                              ? cs.onPrimaryContainer
                              : cs.onTertiaryContainer,
                        ),
                      const Spacer(),
                      EntryActionMenu(
                        entry: sortedEntries[i],
                        onEdit: () => _confirmEdit(context, sortedEntries[i]),
                        onDelete: () =>
                            _confirmDelete(context, sortedEntries[i]),
                        iconSize: 18,
                        iconAlpha: 0.4,
                      ),
                    ],
                  ),
                  if (sortedEntries[i].label != null)
                    const SizedBox(height: AppSpacing.xs),
                  BionicText(
                    text: sortedEntries[i].displayText,
                    // When expanded, let long entries breathe rather than
                    // clip with an ellipsis. The list is already bounded
                    // by the day so there's no unbounded-height risk.
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded
                        ? TextOverflow.clip
                        : TextOverflow.ellipsis,
                    style: tt.bodyMedium?.copyWith(
                      height: 1.5,
                      color: cs.onSurface.withValues(alpha: 0.9),
                    ),
                    enabled: SettingsProvider.maybeOf(
                          context,
                        )?.bionicReadingEnabled ??
                        false,
                  ),
                ],
              ),
            ],
            if (hasMore)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: AppSpacing.borderRadiusSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 16,
                          color: cs.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _expanded
                              ? 'Show less'
                              : '+${sortedEntries.length - 2} more',
                          style: tt.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (reduceMotion) return card;
    return Animate(
      effects: [
        FadeEffect(duration: 380.ms, curve: Curves.easeOut),
        SlideEffect(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
          duration: 420.ms,
          curve: AppMotion.emphasizedDecelerate,
        ),
      ],
      child: card,
    );
  }
}
