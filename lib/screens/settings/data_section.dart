import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart' show setSentryOptIn;
import '../../services/analytics_service.dart';
import '../../services/database_service.dart';
import '../../services/app_log.dart';
import '../../services/export_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/atoms/app_snack_bar.dart';
import '../../widgets/organisms/delete_confirm_dialog.dart';
import '../../services/user_repository.dart' show UserRepository;

/// Settings → Data section.
///
/// Task 10.1 — hosts the Sentry opt-in toggle. The toggle writes to
/// SharedPreferences under key `sentry_opt_in` and calls
/// `setSentryOptIn(bool)` in main.dart so the cached flag that
/// `beforeSend` checks is updated without an app restart. Default OFF.
class DataSection extends StatefulWidget {
  const DataSection({super.key, required this.verifyPinIfNeeded});

  /// Callback that returns true if the user verified their PIN (or lock is disabled).
  final Future<bool> Function(BuildContext context) verifyPinIfNeeded;

  @override
  State<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends State<DataSection> {
  static const _sentryOptInKey = 'sentry_opt_in';
  bool _diagnosticsEnabled = false;
  bool _diagnosticsLoaded = false;

  // Task 11.13 — Analytics kill switch. Default ON because local
  // counters never leave the device (enforced by the Task 12.1
  // no-network CI guard), so the privacy-policy invariant is
  // preserved either way. Users can flip this off to stop on-
  // device writes entirely; existing counter rows are retained
  // (user can re-enable without loss) until Delete All Data.
  bool _keepUsageStats = true;
  bool _keepUsageStatsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadToggles();
  }

  Future<void> _loadToggles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _diagnosticsEnabled = prefs.getBool(_sentryOptInKey) ?? false;
        _diagnosticsLoaded = true;
        _keepUsageStats = AnalyticsService.instance.isEnabled;
        _keepUsageStatsLoaded = true;
      });
    } catch (e, st) {
      AppLog.warn('DataSection.loadToggles', e, st);
      if (!mounted) return;
      setState(() {
        _diagnosticsLoaded = true;
        _keepUsageStatsLoaded = true;
      });
    }
  }

  Future<void> _setDiagnostics(bool value) async {
    setState(() => _diagnosticsEnabled = value);
    // Update the in-process cached flag synchronously so the very
    // next beforeSend call observes the new state — no app restart.
    setSentryOptIn(value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sentryOptInKey, value);
    } catch (e, st) {
      AppLog.warn('DataSection.setDiagnostics', e, st);
    }
  }

  Future<void> _setKeepUsageStats(bool value) async {
    setState(() => _keepUsageStats = value);
    // Task 11.13 — flip the AnalyticsService cached flag
    // immediately so the next `bump(...)` call observes the new
    // state. Also persists via SharedPreferences inside
    // setEnabled so next cold-start honours the toggle.
    await AnalyticsService.instance.setEnabled(value);
  }

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

          // Task 10.1 — Diagnostics (Sentry opt-in toggle). Sits
          // above the danger zone but below Import because it's a
          // standing preference, not a destructive action.
          Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.diagnosticsLabel,
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_diagnosticsLoaded)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.helpImproveRetraq,
                style: tt.bodyLarge,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l10n.helpImproveRetraqBody,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              value: _diagnosticsEnabled,
              onChanged: _setDiagnostics,
            ),

          // Task 11.13 — Analytics kill switch. Sits inside
          // Diagnostics because both are "data you can choose to
          // keep/stop"; distinct from Sentry because nothing here
          // ever leaves the device.
          if (_keepUsageStatsLoaded)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.keepUsageStats,
                style: tt.bodyLarge,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l10n.keepUsageStatsBody,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              value: _keepUsageStats,
              onChanged: _setKeepUsageStats,
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
    if (!await widget.verifyPinIfNeeded(context)) return;
    if (!context.mounted) return;
    final exportAll = await _showExportScopeDialog(context);
    if (exportAll == null || !context.mounted) return;
    // Task 3.9 — require explicit consent before handing a plaintext
    // file to the OS share sheet. The destination app (Gmail, Drive,
    // random editor) would otherwise receive decrypted journal text
    // with no visible warning. This dialog is additive to the export-
    // scope picker; the scope dialog answers "what", this one answers
    // "are you sure you want to hand it to another app?".
    final confirmedShare = await _showPlaintextShareWarning(context);
    if (!confirmedShare || !context.mounted) return;
    try {
      if (json) {
        await ExportService.instance.exportAsJson(exportAll: exportAll);
      } else {
        await ExportService.instance.exportAsText(exportAll: exportAll);
      }
    } catch (e, st) {
      // Task 1.4 — capture the actual export failure so release-mode
      // diagnostics survive. Previously the exception was discarded
      // entirely by `catch (_)`.
      AppLog.error('DataSection.exportBackup', e, st);
      if (!context.mounted) return;
      final l10n = L10n.of(context)!;
      AppSnackBar.error(context, l10n.exportFailed);
    }
  }

  /// Task 3.9 — Confirmation dialog shown before a plaintext export is
  /// handed to the share sheet. Returns true when the user explicitly
  /// chose "Share anyway"; false on cancel or barrier dismiss.
  Future<bool> _showPlaintextShareWarning(BuildContext context) async {
    final l10n = L10n.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.plaintextExportWarningTitle),
        content: Text(l10n.plaintextExportWarningBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.plaintextExportShareAnyway),
          ),
        ],
      ),
    );
    return confirmed == true;
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
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;
      file = result.files.single;
    } catch (e) {
      if (!context.mounted) return;
      final l10n = L10n.of(context)!;
      AppSnackBar.error(context, l10n.filePickerFailed);
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

      AppSnackBar.show(context, l10n.importSuccess(imported, skipped, errors));
    } catch (e) {
      if (!context.mounted) return;
      final l10n = L10n.of(context)!;
      AppSnackBar.error(context, l10n.importFailed);
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
    final confirmed = await DeleteConfirmDialog.show(context);
    if (confirmed != true || !context.mounted) return;

    try {
      await DatabaseService.instance.userRepo.deleteAllData();
      if (!context.mounted) return;
      // Delete succeeded — show a dedicated confirmation dialog that
      // explains what just happened and asks the user to confirm
      // before we close the app. The previous behaviour slammed the
      // app shut with no feedback beyond a snackbar that never got
      // time to paint.
      await _showPostDeleteDialog(context);
      // Whether or not the user tapped the close button above, the
      // in-memory app state (Drift watchers, cached settings, etc.)
      // is referring to wiped rows — closing the process here is the
      // safest path to a fresh next-launch.
      await UserRepository.requestAppExit();
    } catch (e) {
      if (!context.mounted) return;
      final l10n = L10n.of(context)!;
      AppSnackBar.error(context, l10n.deleteDataFailed);
    }
  }

  Future<void> _showPostDeleteDialog(BuildContext context) async {
    final l10n = L10n.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.allDataDeletedTitle),
        content: Text(l10n.allDataDeletedBody),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.closeAppButton),
          ),
        ],
      ),
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
