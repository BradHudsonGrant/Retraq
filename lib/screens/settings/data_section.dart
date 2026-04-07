import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/database_service.dart';
import '../../services/export_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/organisms/delete_confirm_dialog.dart';

class DataSection extends StatelessWidget {
  const DataSection({super.key, required this.verifyPinIfNeeded});

  /// Callback that returns true if the user verified their PIN (or lock is disabled).
  final Future<bool> Function(BuildContext context) verifyPinIfNeeded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          l10n.yourData,
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
              l10n.exportLabel,
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ExportButton(
                  icon: Icons.data_object,
                  label: l10n.exportJson,
                  onPressed: () => _handleExport(context, json: true),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ExportButton(
                  icon: Icons.description_outlined,
                  label: l10n.exportText,
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
              l10n.importLabel,
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _importBackup(context),
              icon: const Icon(Icons.upload_file, size: 18),
              label: Text(l10n.importFromBackup),
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
              l10n.importAccepts,
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
              label: Text(
                l10n.deleteAllData,
                style: TextStyle(color: cs.error),
              ),
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
      final l10n = L10n.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.exportFailed),
          backgroundColor: cs.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusLg,
          ),
        ),
      );
    }
  }

  Future<bool?> _showExportScopeDialog(BuildContext context) {
    final l10n = L10n.of(context)!;
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.exportScopeTitle),
            content: Text(l10n.exportScopeContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancelLabel),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.thisWeek),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.allEntries),
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
      final l10n = L10n.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.filePickerFailed),
          backgroundColor: cs.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusLg,
          ),
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
      final l10n = L10n.of(context)!;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.importSuccess(
              imported,
              skipped > 0 ? ', $skipped duplicates skipped' : '',
              errors > 0 ? ', $errors errors' : '',
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusLg,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final cs = Theme.of(context).colorScheme;
      final l10n = L10n.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.importFailed),
          backgroundColor: cs.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusLg,
          ),
        ),
      );
    }
  }

  Future<bool> _confirmImport(BuildContext context, String filename) async {
    final l10n = L10n.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.importConfirmTitle(filename)),
            content: Text(l10n.importConfirmContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancelLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.importButton),
              ),
            ],
          ),
    );
    return confirmed == true;
  }

  Future<void> _confirmDeleteAllData(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await DeleteConfirmDialog.show(context);
    if (confirmed != true || !context.mounted) return;

    try {
      await DatabaseService.instance.userRepo.deleteAllData();
      if (!context.mounted) return;
      final l10n = L10n.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.allDataDeleted),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusLg,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final l10n = L10n.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.deleteDataFailed,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onErrorContainer),
          ),
          backgroundColor: cs.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusLg,
          ),
        ),
      );
    }
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
