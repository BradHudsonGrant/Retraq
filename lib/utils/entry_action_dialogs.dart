import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../services/database_service.dart';
import '../widgets/organisms/edit_entry_sheet.dart';

/// Shared confirmation dialogs for editing and deleting journal entries.
/// Used across RecapScreen, EntryDetailView, WeekDayList, and HomeScreen.

/// Opens EditEntrySheet directly for the given entry.
/// Returns true if the entry was modified.
Future<bool> confirmAndEditEntry(BuildContext context, JournalEntry entry) async {
  if (!context.mounted) return false;
  final changed = await EditEntrySheet.show(context, entry);
  return changed == true;
}

/// Shows a "Delete entry?" confirmation, then deletes the entry.
/// Returns true if the entry was deleted.
Future<bool> confirmAndDeleteEntry(BuildContext context, JournalEntry entry) async {
  final cs = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete entry?'),
      content: const Text("This can't be undone."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  if (entry.id == null) return false;
  try {
    await DatabaseService.instance.entries.deleteEntry(entry.id!);
    return true;
  } catch (e) {
    debugPrint('confirmAndDeleteEntry failed: $e');
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to delete. Please try again.')),
    );
    return false;
  }
}
