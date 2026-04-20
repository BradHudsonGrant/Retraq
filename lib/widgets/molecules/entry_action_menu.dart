// ignore_for_file: prefer_single_quotes

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/journal_entry.dart';
import '../../theme/app_spacing.dart';

/// Shared popup menu for journal entry actions (edit, delete, share).
class EntryActionMenu extends StatelessWidget {
  const EntryActionMenu({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    this.onShare,
    this.iconSize = 20,
    this.iconAlpha = 0.5,
  });

  final JournalEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onShare;
  final double iconSize;
  final double iconAlpha;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = L10n.of(context)!;
    // route through existing ARB keys (entryActions,
    // editAction, shareAction, deleteAction) which already live in
    // the localisation bundle. Previously hardcoded English even
    // though the keys were ready.
    return SizedBox(
      width: 48,
      height: 48,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: iconSize,
        icon: Icon(
          Icons.more_vert,
          color: cs.onSurfaceVariant.withValues(alpha: iconAlpha),
        ),
        tooltip: l10n.entryActions,
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit();
            case 'share':
              onShare?.call();
            case 'delete':
              onDelete();
          }
        },
        itemBuilder:
            (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.editAction),
                  ],
                ),
              ),
              if (onShare != null)
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      const Icon(Icons.share_outlined, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.shareAction),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.deleteAction),
                  ],
                ),
              ),
            ],
      ),
    );
  }
}
