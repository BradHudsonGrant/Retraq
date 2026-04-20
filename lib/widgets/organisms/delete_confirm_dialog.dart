import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';

/// Confirmation dialog that forces the user to type "DELETE" before they can
/// complete a destructive wipe action.
///
/// Pops `true` when confirmed, `false` (or `null` on barrier dismiss) when
/// cancelled. Callers await [show] and handle the three outcomes:
///
/// ```dart
/// final confirmed = await DeleteConfirmDialog.show(context);
/// if (confirmed != true) return;
/// await DatabaseService.instance.userRepo.deleteAllData();
/// ```
class DeleteConfirmDialog extends StatefulWidget {
  const DeleteConfirmDialog({super.key});

  /// Convenience wrapper around [showDialog]. Returns `true` iff the user
  /// typed DELETE and tapped the confirm button.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const DeleteConfirmDialog(),
    );
  }

  @override
  State<DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<DeleteConfirmDialog> {
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final valid = _controller.text.trim() == 'DELETE';
      if (valid != _isValid) setState(() => _isValid = valid);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = L10n.of(context)!;
    return AlertDialog(
      title: Text(l10n.deleteAllDataTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteAllDataContent),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.typeDeleteToConfirm,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'DELETE',
              border: const OutlineInputBorder(),
              isDense: true,
              errorText:
                  _controller.text.isNotEmpty && !_isValid
                      ? l10n.typeDeleteError
                      : null,
              // lift errorText from default bodySmall (12pt)
              // to bodyMedium (14pt) so it clears the WCAG "large-text"
              // exception threshold and keeps comfortable contrast on
              // colorScheme.error against dialog surface (~4.7:1).
              errorStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.error,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          onPressed: _isValid ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          child: Text(
            l10n.deleteEverything,
            style: TextStyle(color: _isValid ? cs.onError : null),
          ),
        ),
      ],
    );
  }
}
