import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:retraq/l10n/app_localizations.dart';

import '../../models/journal_entry.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../utils/test_keys.dart';
import '../../widgets/atoms/glow_box.dart';
import '../../widgets/molecules/entry_action_menu.dart';

/// Search bar + results section of the Recap screen.
class RecapSearchView extends StatelessWidget {
  const RecapSearchView({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.searchResults,
    required this.isSearching,
    required this.hasSearched,
    required this.onEdit,
    required this.onDelete,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final List<JournalEntry> searchResults;
  final bool isSearching;
  final bool hasSearched;
  final void Function(JournalEntry entry) onEdit;
  final void Function(JournalEntry entry) onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;
    final reduceMotion = AppMotion.reduce(context);

    final searchField = TextField(
      key: TestKeys.recapSearchField,
      controller: searchController,
      onChanged: onSearchChanged,
      autofocus: true,
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon:
            searchController.text.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    onSearchChanged('');
                  },
                )
                : null,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        filled: true,
        fillColor: cs.surfaceContainerHigh,
      ),
    );

    // Previously wrapped in
    // `CustomScrollView(shrinkWrap: true, physics: NeverScrollableScrollPhysics)`
    // with SliverToBoxAdapter + SliverList.builder inside the parent
    // SingleChildScrollView. That defeated SliverList's lazy-build —
    // every result card materialised on first frame anyway. Use plain
    // Column + List.generate which is semantically identical but
    // removes sliver overhead and clarifies intent.
    //
    // True virtualisation at scale (500+ search results, e.g. FTS5 query
    // over multi-year journal) requires restructuring the recap screen
    // into a single CustomScrollView with slivers. Deferred as a v1.1
    // architectural change; FTS5 search already LIMITs to 50 results
    // by default so this is not a live scaling bottleneck today.

    // Header (search box).
    final searchFieldHeader = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        Animate(
          effects: [
            FadeEffect(duration: 360.ms, curve: Curves.easeOut),
            SlideEffect(
              begin: const Offset(0, -0.04),
              end: Offset.zero,
              duration: 400.ms,
              curve: AppMotion.emphasizedDecelerate,
            ),
          ],
          child: GlowBox(
            color: cs.primary,
            glowOpacity: 0.32,
            blurRadius: 24,
            spreadRadius: 0,
            borderRadius: AppSpacing.borderRadiusLg,
            child: searchField,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );

    // Status: searching indicator, empty state, or nothing.
    final Widget? statusWidget;
    if (isSearching) {
      statusWidget = Semantics(
        liveRegion: true,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Text(
              l10n.searching,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    } else if (hasSearched && searchResults.isEmpty) {
      statusWidget = Semantics(
        liveRegion: true,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Text(
              l10n.noSearchResults,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    } else {
      statusWidget = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchFieldHeader,
        if (statusWidget != null)
          statusWidget
        else if (searchResults.isNotEmpty)
          ...List<Widget>.generate(searchResults.length, (index) {
              final entry = searchResults[index];
              final card = Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  // Shared content-card tier.
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: AppSpacing.borderRadiusLg,
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat('MMM d, yyyy').format(entry.date),
                            style: tt.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (entry.label != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              entry.label!,
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const Spacer(),
                          EntryActionMenu(
                            entry: entry,
                            onEdit: () => onEdit(entry),
                            onDelete: () => onDelete(entry),
                            iconAlpha: 0.65,
                          ),
                        ],
                      ),
                      if (entry.title != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        _highlightText(
                          entry.title!,
                          searchController.text.trim(),
                          tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          cs,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      _highlightText(
                        entry.displayText,
                        searchController.text.trim(),
                        tt.bodyMedium,
                        cs,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              );
              if (reduceMotion) return card;
              final delayMs = (index * 55).clamp(0, 660);
              return Animate(
                effects: [
                  FadeEffect(
                    delay: delayMs.ms,
                    duration: 360.ms,
                    curve: Curves.easeOut,
                  ),
                  SlideEffect(
                    delay: delayMs.ms,
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                    duration: 420.ms,
                    curve: AppMotion.emphasizedDecelerate,
                  ),
                ],
                child: card,
              );
            }),
      ],
    );
  }

  /// Build a TextSpan that highlights occurrences of [query] in [text].
  Widget _highlightText(
    String text,
    String query,
    TextStyle? baseStyle,
    ColorScheme cs, {
    int? maxLines,
  }) {
    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      );
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: TextStyle(
            backgroundColor: cs.primaryContainer,
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      start = idx + query.length;
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}
