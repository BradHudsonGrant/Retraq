import 'package:flutter/material.dart';
import '../../models/journal_entry.dart';
import '../../services/database_service.dart';
import '../../theme/app_spacing.dart';
import '../atoms/sincethen_button.dart';
import '../molecules/mood_selector.dart';

/// Bottom sheet for editing or deleting an existing journal entry.
/// Shows editable text fields pre-filled with the entry's content.
class EditEntrySheet extends StatefulWidget {
  const EditEntrySheet({super.key, required this.entry});

  final JournalEntry entry;

  /// Show the edit sheet as a modal bottom sheet. Returns true if the entry
  /// was modified or deleted (so the caller can refresh).
  static Future<bool?> show(BuildContext context, JournalEntry entry) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => EditEntrySheet(entry: entry),
    );
  }

  @override
  State<EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends State<EditEntrySheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _entryCtrl;
  int? _mood;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.entry.title ?? '');
    _entryCtrl = TextEditingController(text: widget.entry.entry ?? '');
    _mood = widget.entry.mood;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final label = widget.entry.label;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Edit Entry',
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (label != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: label == 'AM'
                              ? cs.primaryContainer
                              : cs.tertiaryContainer,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          label,
                          style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: label == 'AM'
                                ? cs.onPrimaryContainer
                                : cs.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                IconButton(
                  onPressed: _confirmDelete,
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  tooltip: 'Delete entry',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Title field
            if (widget.entry.title != null) ...[
              TextField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Title',
                  labelText: 'Title',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  hintStyle: tt.titleMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                  border: InputBorder.none,
                ),
              ),
              Divider(color: cs.outlineVariant),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Mood selector
            if (widget.entry.mood != null || _mood != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: MoodSelector(
                  selectedMood: _mood,
                  onChanged: (v) => setState(() => _mood = v),
                ),
              ),

            // Entry text field
            _buildEditField(_entryCtrl, 'Entry text...'),

            const SizedBox(height: AppSpacing.lg),

            // Save button
            SizedBox(
              width: double.infinity,
              child: SinceThenButton(
                label: _isSaving ? 'Saving...' : 'Save Changes',
                icon: Icons.check,
                onPressed: _isSaving ? null : _save,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(TextEditingController ctrl, String hint) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: TextField(
        controller: ctrl,
        textCapitalization: TextCapitalization.sentences,
        maxLines: null,
        minLines: 3,
        style: tt.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          labelText: 'Entry text',
          floatingLabelBehavior: FloatingLabelBehavior.never,
          hintStyle: tt.bodyLarge?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          contentPadding: const EdgeInsets.all(AppSpacing.md),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!mounted) return;
    setState(() => _isSaving = true);

    final titleText = _titleCtrl.text.trim();
    final entryText = _entryCtrl.text.trim();

    final updatedEntry = JournalEntry(
      id: widget.entry.id,
      date: widget.entry.date,
      entry: entryText.isEmpty ? null : entryText,
      label: widget.entry.label,
      title: titleText.isEmpty ? null : titleText,
      mood: _mood,
      createdAt: widget.entry.createdAt,
      userId: widget.entry.userId,
    );

    try {
      await DatabaseService.instance.entries.saveEntry(updatedEntry);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('EditEntrySheet._save failed: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Please try again.')),
      );
    }
  }

  void _confirmDelete() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                if (widget.entry.id != null) {
                  await DatabaseService.instance.entries.deleteEntry(widget.entry.id!);
                }
                if (!mounted) return;
                Navigator.of(context).pop(true);
              } catch (e) {
                debugPrint('EditEntrySheet._confirmDelete failed: $e');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete. Please try again.')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: cs.error)),
          ),
        ],
      ),
    );
  }
}
