import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/export_service.dart';
import '../../theme/app_spacing.dart';

class DataSection extends StatelessWidget {
  const DataSection({
    super.key,
    required this.verifyPinIfNeeded,
  });

  /// Callback that returns true if the user verified their PIN (or lock is disabled).
  final Future<bool> Function(BuildContext context) verifyPinIfNeeded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          'Your Data',
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        children: [
          // Export
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Export',
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ExportButton(
                  icon: Icons.data_object,
                  label: 'Export JSON',
                  onPressed: () => _handleExport(context, json: true),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ExportButton(
                  icon: Icons.description_outlined,
                  label: 'Export Text',
                  onPressed: () => _handleExport(context, json: false),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Import
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Import',
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _importBackup(context),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Import from Backup'),
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Accepts SinceThen JSON backup files only',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Danger zone
          Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDeleteAllData(context),
              icon: Icon(Icons.delete_forever, size: 18, color: cs.error),
              label: Text('Delete All Data', style: TextStyle(color: cs.error)),
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(BuildContext context, {required bool json}) async {
    if (!await verifyPinIfNeeded(context)) return;
    if (!context.mounted) return;
    final exportAll = await _showExportScopeDialog(context);
    if (exportAll == null || !context.mounted) return;
    try {
      if (json) {
        await ExportService.instance.exportAsJson(exportAll: exportAll);
      } else {
        await ExportService.instance.exportAsText(exportAll: exportAll);
      }
    } catch (_) {
      if (!context.mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Export failed. Please try again.'),
          backgroundColor: cs.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        ),
      );
    }
  }

  Future<bool?> _showExportScopeDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export scope'),
        content: const Text(
          'Export this week\u2019s entries or all entries?\n\n'
          'The export will include your journal entries, settings, and any '
          'profile information you\'ve provided (such as display name or '
          'email). Keep it somewhere safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('This Week'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('All Entries'),
          ),
        ],
      ),
    );
  }

  Future<void> _importBackup(BuildContext context) async {
    final PlatformFile file;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;
      file = result.files.single;
    } catch (e) {
      if (!context.mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open file picker. Please try again.'),
          backgroundColor: cs.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        ),
      );
      return;
    }
    if (!context.mounted) return;

    final shouldImport = await _confirmImport(context, file.name);
    if (!shouldImport || !context.mounted) return;

    try {
      final filePath = file.path!;
      final summary = await ExportService.instance.importFromJson(filePath);
      if (!context.mounted) return;

      final imported = summary['imported'] ?? 0;
      final skipped = summary['skipped'] ?? 0;
      final errors = summary['errors'] ?? 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported $imported entries'
            '${skipped > 0 ? ', $skipped duplicates skipped' : ''}'
            '${errors > 0 ? ', $errors errors' : ''}',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Import failed. The file may be corrupted or in the wrong format.'),
          backgroundColor: cs.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        ),
      );
    }
  }

  Future<bool> _confirmImport(BuildContext context, String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Import $filename?'),
        content: const Text(
          'This will add entries from this backup to your journal. '
          'Duplicate entries will be skipped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _confirmDeleteAllData(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteConfirmDialog(colorScheme: cs),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await DatabaseService.instance.userRepo.deleteAllData();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All data has been deleted.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete data. Please try again.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onErrorContainer,
            ),
          ),
          backgroundColor: cs.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        ),
      );
    }
  }
}

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
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
    final cs = widget.colorScheme;
    return AlertDialog(
      title: const Text('Delete all data?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This will permanently delete all journal entries and reset '
            'your settings. This cannot be undone.'
            '\n\nConsider exporting your data first from the options above.',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Type DELETE to confirm:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
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
              errorText: _controller.text.isNotEmpty && !_isValid
                  ? 'Type DELETE to confirm'
                  : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isValid ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          child: Text(
            'Delete Everything',
            style: TextStyle(color: _isValid ? cs.onError : null),
          ),
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
    );
  }
}
