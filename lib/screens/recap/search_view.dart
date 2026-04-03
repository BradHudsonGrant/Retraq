import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/journal_entry.dart';
import '../../theme/app_spacing.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search entries...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isNotEmpty
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
        ),
        const SizedBox(height: AppSpacing.md),

        // Search results
        if (isSearching)
          Semantics(
            liveRegion: true,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  'Searching...',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          )
        else if (hasSearched && searchResults.isEmpty)
          Semantics(
            liveRegion: true,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  'No entries match your search.',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          )
        else if (searchResults.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final entry = searchResults[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                          tt.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
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
            },
          ),
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
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          backgroundColor: cs.primaryContainer,
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ));
      start = idx + query.length;
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}
