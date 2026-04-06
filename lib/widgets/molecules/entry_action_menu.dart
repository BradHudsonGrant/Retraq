// ignore_for_file: prefer_single_quotes

import 'package:flutter/material.dart';
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
        tooltip: 'Entry actions',
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
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: AppSpacing.sm),
                    Text('Edit'),
                  ],
                ),
              ),
              if (onShare != null)
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined, size: 18),
                      SizedBox(width: AppSpacing.sm),
                      Text('Share'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18),
                    SizedBox(width: AppSpacing.sm),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
      ),
    );
  }
}
