import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../models/user_settings.dart';
import '../../services/pin_service.dart';
import '../../theme/app_spacing.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXxl)),
      ),
      builder: (_) => const PinSetupSheet(),
    );
    if (pin != null && mounted) {
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXxl)),
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

  Future<bool> _verifyPinIfNeeded(BuildContext context) async {
    final s = widget.settings;
    if (!s.appLockEnabled || s.pinHash == null) return true;
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final s = widget.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Security', style: tt.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Keep your journal private.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),

        SettingsRow(
          title: 'App Lock',
          subtitle: s.appLockEnabled
              ? 'PIN required to open SinceThen'
              : 'No lock — anyone can open the app',
          trailing: Semantics(
            label: 'App lock',
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
            title: 'Change PIN',
            subtitle: 'Set a new PIN',
            trailing: IconButton(
              icon: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              onPressed: () async {
                if (!await _verifyPinIfNeeded(context)) return;
                if (!mounted) return;
                _showPinSetup(context);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsRow(
            title: 'Biometric Unlock',
            subtitle: 'Use fingerprint or face to unlock',
            trailing: Semantics(
              label: 'Biometric unlock',
              child: Switch(
                value: s.biometricEnabled,
                onChanged: _checkingBiometric
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
                                  'Biometrics not available on this device',
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onErrorContainer,
                                  ),
                                ),
                                backgroundColor: cs.errorContainer,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: AppSpacing.borderRadiusLg),
                              ),
                            );
                            return;
                          }
                          // Require PIN verification before enabling biometrics.
                          if (!mounted) return;
                          final verified = await _verifyPinIfNeeded(context);
                          if (!verified || !mounted) return;
                        }
                        widget.onSettingsChanged(s.copyWith(biometricEnabled: v));
                        if (v && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Biometric unlock enabled — you\u2019ll be prompted next time you open SinceThen',
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                              backgroundColor: cs.primaryContainer,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppSpacing.borderRadiusLg),
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
