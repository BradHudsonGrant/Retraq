import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_settings.dart';
import '../widgets/settings_provider.dart';
import '../services/database_service.dart';
import '../services/settings_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../utils/adaptive_layout.dart';
import '../utils/pin_dialogs.dart';
import '../utils/test_keys.dart';
import '../widgets/atoms/retraq_logo.dart';
import '../widgets/organisms/nudge_card.dart';
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

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final SettingsRepository _settingsRepo = DatabaseService.instance.settings;

  UserSettings get _settings => SettingsProvider.of(context);

  Future<void> _save(UserSettings updated) async {
    await _settingsRepo.saveSettings(updated);
  }

  Future<bool> _verifyPinIfNeeded(BuildContext context) {
    final s = _settings;
    return verifyPinIfNeeded(
      context,
      appLockEnabled: s.appLockEnabled,
      pinHash: s.pinHash,
    );
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
      await NotificationService.instance.scheduleDaily(
        picked.hour,
        minute: picked.minute,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = _settings;

    Widget enter(Widget child, int delayMs) {
      return Animate(
        effects: [
          FadeEffect(
            delay: delayMs.ms,
            duration: 450.ms,
            curve: Curves.easeOut,
          ),
          SlideEffect(
            delay: delayMs.ms,
            begin: const Offset(0, 0.08),
            end: Offset.zero,
            duration: 500.ms,
            curve: AppMotion.emphasizedDecelerate,
          ),
        ],
        child: child,
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),

        enter(const RetraqLogo(size: 22), 0),
        const SizedBox(height: AppSpacing.lg),

        enter(
          AppearanceSection(
            key: TestKeys.settingsAppearanceSection,
            themeMode: widget.themeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
          ),
          0,
        ),

        const SizedBox(height: AppSpacing.xl),

        enter(
          PreferencesSection(
            key: TestKeys.settingsPreferencesSection,
            settings: s,
            onSettingsChanged: _save,
          ),
          60,
        ),

        const SizedBox(height: AppSpacing.xl),

        enter(
          SecuritySection(
            key: TestKeys.settingsSecuritySection,
            settings: s,
            onSettingsChanged: _save,
          ),
          120,
        ),

        const SizedBox(height: AppSpacing.xl),

        enter(
          NudgeCard(
            key: TestKeys.settingsNudgeCard,
            nudgeHour: s.nudgeHour,
            nudgeMinute: s.nudgeMinute,
            onChangeTime: () => _showTimePicker(context),
          ),
          180,
        ),

        const SizedBox(height: AppSpacing.xl),

        enter(
          DataSection(
            key: TestKeys.settingsDataSection,
            verifyPinIfNeeded: _verifyPinIfNeeded,
          ),
          240,
        ),

        const SizedBox(height: AppSpacing.xl),

        enter(const LegalFooter(key: TestKeys.settingsLegalFooter), 300),

        const SizedBox(height: AppSpacing.navBarClearance),
      ],
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child:
            isTablet(context)
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
