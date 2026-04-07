import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_settings.dart';
import '../../providers/settings_provider.dart';
import '../../services/pin_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/pin_dialogs.dart';
import '../../widgets/atoms/bionic_text.dart';
import '../../widgets/molecules/settings_row.dart';
import '../../widgets/organisms/pin_setup_sheet.dart';
import '../../widgets/organisms/pin_verify_sheet.dart';

class SecuritySection extends StatefulWidget {
  const SecuritySection({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final UserSettings settings;
  final ValueChanged<UserSettings> onSettingsChanged;

  @override
  State<SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<SecuritySection> {
  bool _checkingBiometric = false;

  Future<bool> _checkBiometrics() async {
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<void> _showPinSetup(BuildContext context) async {
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      builder: (_) => const PinSetupSheet(),
    );
    if (pin != null && context.mounted) {
      // Dismiss any keyboard that might reappear when the sheet closes.
      FocusScope.of(context).unfocus();
      final hash = await PinService.hashPin(pin);
      if (!mounted) return;
      widget.onSettingsChanged(
        widget.settings.copyWith(pinHash: hash, appLockEnabled: true),
      );
    }
  }

  Future<void> _showPinVerifyToDisable(BuildContext context) async {
    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      builder: (_) => PinVerifySheet(pinHash: widget.settings.pinHash!),
    );
    if (verified == true && mounted) {
      widget.onSettingsChanged(
        widget.settings.copyWith(
          appLockEnabled: false,
          pinHash: null,
          biometricEnabled: false,
        ),
      );
    }
  }

  Future<bool> _verifyPinIfNeeded(BuildContext context) {
    final s = widget.settings;
    return verifyPinIfNeeded(
      context,
      appLockEnabled: s.appLockEnabled,
      pinHash: s.pinHash,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;
    final s = widget.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.securityTitle, style: tt.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        BionicText(
          text: l10n.securitySubtitle,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          enabled:
              SettingsProvider.maybeOf(context)?.bionicReadingEnabled ?? false,
        ),
        const SizedBox(height: AppSpacing.md),

        SettingsRow(
          title: l10n.appLock,
          subtitle:
              s.appLockEnabled ? l10n.appLockEnabled : l10n.appLockDisabled,
          trailing: Semantics(
            label: l10n.appLockA11y,
            child: Switch(
              value: s.appLockEnabled,
              onChanged: (v) {
                if (v) {
                  _showPinSetup(context);
                } else {
                  _showPinVerifyToDisable(context);
                }
              },
              activeColor: cs.primary,
            ),
          ),
        ),

        if (s.appLockEnabled) ...[
          const SizedBox(height: AppSpacing.md),
          SettingsRow(
            title: l10n.changePin,
            subtitle: l10n.changePinSubtitle,
            trailing: IconButton(
              icon: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              onPressed: () async {
                if (!await _verifyPinIfNeeded(context)) return;
                if (!context.mounted) return;
                _showPinSetup(context);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsRow(
            title: l10n.biometricUnlock,
            subtitle: l10n.biometricSubtitle,
            trailing: Semantics(
              label: l10n.biometricUnlockA11y,
              child: Switch(
                value: s.biometricEnabled,
                onChanged:
                    _checkingBiometric
                        ? null
                        : (v) async {
                          if (v) {
                            setState(() => _checkingBiometric = true);
                            final messenger = ScaffoldMessenger.of(context);
                            final canAuth = await _checkBiometrics();
                            if (!mounted) return;
                            setState(() => _checkingBiometric = false);
                            if (!canAuth) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.biometricUnavailable,
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onErrorContainer,
                                    ),
                                  ),
                                  backgroundColor: cs.errorContainer,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppSpacing.borderRadiusLg,
                                  ),
                                ),
                              );
                              return;
                            }
                            // Require PIN verification before enabling biometrics.
                            if (!context.mounted) return;
                            final verified = await _verifyPinIfNeeded(context);
                            if (!verified || !context.mounted) return;
                          }
                          widget.onSettingsChanged(
                            s.copyWith(biometricEnabled: v),
                          );
                          if (v && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.biometricEnabledMessage,
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                                backgroundColor: cs.primaryContainer,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppSpacing.borderRadiusLg,
                                ),
                              ),
                            );
                          }
                        },
                activeColor: cs.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
