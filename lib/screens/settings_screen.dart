import 'package:flutter/material.dart';
import '../models/user_settings.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../services/settings_repository.dart';
import '../services/notification_service.dart';
import '../providers/premium_provider.dart';
import '../theme/app_spacing.dart';
import 'paywall_screen.dart';
import '../utils/adaptive_layout.dart';
import '../widgets/organisms/nudge_card.dart';
import '../widgets/organisms/pin_verify_sheet.dart';
import 'settings/appearance_section.dart';
import 'settings/data_section.dart';
import 'settings/legal_footer.dart';
import 'settings/preferences_section.dart';
import 'settings/security_section.dart';

/// Settings screen — appearance, preferences, and nudge configuration.
/// All settings persist to Drift (SQLite) via DatabaseService.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.onThemeModeChanged,
    required this.themeMode,
  });

  final Future<void> Function(int) onThemeModeChanged;
  final ThemeMode themeMode;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsRepository _settingsRepo = DatabaseService.instance.settings;

  UserSettings get _settings => SettingsProvider.of(context);

  Future<void> _save(UserSettings updated) async {
    await _settingsRepo.saveSettings(updated);
  }

  Future<bool> _verifyPinIfNeeded(BuildContext context) async {
    final s = _settings;
    if (!s.appLockEnabled || s.pinHash == null) {
      return true;
    }
    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXxl)),
      ),
      builder: (_) => PinVerifySheet(pinHash: s.pinHash!),
    );
    return verified == true;
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final s = _settings;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.nudgeHour, minute: s.nudgeMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusXxl,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      _save(s.copyWith(nudgeHour: picked.hour, nudgeMinute: picked.minute));
      await NotificationService.instance.requestPermission();
      await NotificationService.instance.scheduleDaily(picked.hour, minute: picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;

    final isPremium = PremiumProvider.of(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),

        // ── Premium upsell / status ──
        if (!isPremium) ...[
          _PremiumBanner(onTap: () => PaywallScreen.show(context)),
          const SizedBox(height: AppSpacing.xl),
        ],

        AppearanceSection(
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
        ),

        const SizedBox(height: AppSpacing.xl),

        PreferencesSection(
          settings: s,
          onSettingsChanged: _save,
        ),

        const SizedBox(height: AppSpacing.xl),

        SecuritySection(
          settings: s,
          onSettingsChanged: _save,
        ),

        const SizedBox(height: AppSpacing.xl),

        NudgeCard(
          nudgeHour: s.nudgeHour,
          onChangeTime: () => _showTimePicker(context),
        ),

        const SizedBox(height: AppSpacing.xl),

        DataSection(verifyPinIfNeeded: _verifyPinIfNeeded),

        const SizedBox(height: AppSpacing.xl),

        const LegalFooter(),

        const SizedBox(height: AppSpacing.navBarClearance),
      ],
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: isTablet(context)
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: content,
                ),
              )
            : content,
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _PremiumBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: AppSpacing.borderRadiusXl,
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: cs.onPrimaryContainer),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SinceThen Pro',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Unlock AI recaps and advanced analytics',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onPrimaryContainer),
          ],
        ),
      ),
    );
  }
}
