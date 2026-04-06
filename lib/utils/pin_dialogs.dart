import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../widgets/organisms/pin_verify_sheet.dart';

/// Shows a [PinVerifySheet] bottom sheet and returns `true` if the user
/// successfully verified their PIN.  Returns `true` immediately when
/// [appLockEnabled] is false or [pinHash] is null (no lock configured).
Future<bool> verifyPinIfNeeded(
  BuildContext context, {
  required bool appLockEnabled,
  required String? pinHash,
}) async {
  if (!appLockEnabled || pinHash == null) return true;
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
    builder: (_) => PinVerifySheet(pinHash: pinHash),
  );
  return verified == true;
}
