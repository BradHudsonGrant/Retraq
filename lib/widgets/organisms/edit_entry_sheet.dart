import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import '../../models/journal_entry.dart';
import '../../services/database_service.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../atoms/app_snack_bar.dart';
import '../atoms/retraq_button.dart';
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
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
    final l10n = L10n.of(context)!;
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
        child: Animate(
          effects: [
            FadeEffect(duration: 380.ms, curve: Curves.easeOut),
            SlideEffect(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
              duration: 420.ms,
              curve: AppMotion.emphasizedDecelerate,
            ),
          ],
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
                        l10n.editEntry,
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
                            color:
                                label == 'AM'
                                    ? cs.primaryContainer
                                    : cs.tertiaryContainer,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: Text(
                            label,
                            style: tt.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color:
                                  label == 'AM'
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
                    tooltip: l10n.deleteEntryTooltip,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Title field
              TextField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: l10n.titleHint,
                  labelText: l10n.titleHint,
                  // WCAG 3.3.2: keep the label visible at all times so users
                  // (and screen readers) always know what the field is for.
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  // Task 7.1 — alpha 0.75 to meet WCAG 1.4.3 AA.
                  hintStyle: tt.titleMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              Divider(color: cs.outlineVariant),
              const SizedBox(height: AppSpacing.sm),

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
              _buildEditField(_entryCtrl, l10n.entryTextHint),

              const SizedBox(height: AppSpacing.lg),

              // Save button
              SizedBox(
                width: double.infinity,
                child: RetraqButton(
                  label: _isSaving ? l10n.saving : l10n.saveChanges,
                  icon: Icons.check,
                  onPressed: _isSaving ? null : _save,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(TextEditingController ctrl, String hint) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

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
          labelText: l10n.entryTextLabel,
          // WCAG 3.3.2: keep the label visible at all times so users
          // (and screen readers) always know what the field is for.
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          // Task 7.1 — alpha 0.75 to meet WCAG 1.4.3 AA.
          hintStyle: tt.bodyLarge?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.75),
          ),
          contentPadding: const EdgeInsets.all(AppSpacing.md),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!mounted) return;
    final l10n = L10n.of(context)!;

    final titleText = _titleCtrl.text.trim();
    final entryText = _entryCtrl.text.trim();

    // Block saving a completely empty entry (no text, no title, no mood).
    if (titleText.isEmpty && entryText.isEmpty && _mood == null) {
      AppSnackBar.show(context, l10n.entryEmptyMessage);
      return;
    }

    setState(() => _isSaving = true);

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
      AppSnackBar.error(context, l10n.saveFailedMessage);
    }
  }

  void _confirmDelete() {
    final cs = Theme.of(context).colorScheme;
    final l10n = L10n.of(context)!;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.deleteEntryTitle),
            content: Text(l10n.deleteEntryMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancelLabel),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    if (widget.entry.id != null) {
                      await DatabaseService.instance.entries.deleteEntry(
                        widget.entry.id!,
                      );
                    }
                    if (!mounted) return;
                    Navigator.of(context).pop(true);
                  } catch (e) {
                    debugPrint('EditEntrySheet._confirmDelete failed: $e');
                    if (!mounted) return;
                    AppSnackBar.error(context, l10n.deleteFailedMessage);
                  }
                },
                child: Text(
                  l10n.deleteLabel,
                  style: TextStyle(color: cs.error),
                ),
              ),
            ],
          ),
    );
  }
}
