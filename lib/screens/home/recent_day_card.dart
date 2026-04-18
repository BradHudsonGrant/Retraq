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
        // Tightened from lg/lg to md/md — a one-word entry wouldn't
        // fill the card's content area and the 48px vertical padding
        // made the card feel oversized relative to its payload.
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        // surfaceContainerLow (only ~8 RGB levels off the base in dark
        // mode) was disappearing against the ambient gradient's dark
        // foot. Use surfaceContainerHigh for a clearer lift, add a
        // low-alpha outline for a crisp edge, and a soft drop shadow
        // so the card feels raised off the gradient instead of pasted
        // onto it.
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.18),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(Icons.history, size: 14, color: cs.primary),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  widget.label,
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${sortedEntries.length} ${sortedEntries.length == 1 ? 'entry' : 'entries'}',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < sortedEntries.length && i < visibleCount; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              // When an entry has no AM/PM label pill there's no value
              // in spending a whole row on the action menu — inline it
              // next to the text via a Stack so single-word entries
              // don't reserve a 24px action row above their content.
              if (sortedEntries[i].label != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
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
                ),
              // Text body + inline trailing action for unlabelled
              // entries. The action menu is a 48×48 tap target (for
              // touch-target a11y), so the row is always at least 48px
              // tall even if the text is a single word. Center-align
              // cross-axis so one-line entries read as centred on the
              // menu icon instead of clinging to the top of the row.
              if (sortedEntries[i].label == null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        // Nudge the text down a hair so a single line
                        // lines up with the optical centre of the ⋮
                        // icon rather than the geometric centre of its
                        // 48px tap target.
                        padding: const EdgeInsets.only(left: AppSpacing.xxs),
                        child: BionicText(
                          text: sortedEntries[i].displayText,
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded
                              ? TextOverflow.clip
                              : TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(
                            height: 1.35,
                            color: cs.onSurface.withValues(alpha: 0.9),
                          ),
                          enabled: SettingsProvider.maybeOf(
                                context,
                              )?.bionicReadingEnabled ??
                              false,
                        ),
                      ),
                    ),
                    EntryActionMenu(
                      entry: sortedEntries[i],
                      onEdit: () => _confirmEdit(context, sortedEntries[i]),
                      onDelete: () =>
                          _confirmDelete(context, sortedEntries[i]),
                      iconSize: 18,
                      iconAlpha: 0.4,
                    ),
                  ],
                )
              else
                BionicText(
                  text: sortedEntries[i].displayText,
                  maxLines: _expanded ? null : 2,
                  overflow: _expanded
                      ? TextOverflow.clip
                      : TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(
                    height: 1.35,
                    color: cs.onSurface.withValues(alpha: 0.9),
                  ),
                  enabled: SettingsProvider.maybeOf(
                        context,
                      )?.bionicReadingEnabled ??
                      false,
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
