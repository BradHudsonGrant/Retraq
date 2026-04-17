import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../../utils/test_keys.dart';

/// Optional-title input field shown above the traq body on Home.
///
/// Task 1.2 — extracted from `home_screen.dart::_buildTitleField`.
/// Pure presentational widget: the parent owns the
/// [TextEditingController] and any save/validation logic; this widget
/// just draws the bordered surface, applies the decoration, and
/// renders the TextField. Keeps home_screen free of inline styling
/// noise and makes the field trivially unit-testable.
///
/// Uses the already-in-place [TestKeys.homeTitleField] so existing
/// widget tests that locate it by key continue to work post-extraction.
class TitleField extends StatelessWidget {
  const TitleField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: TextField(
        key: TestKeys.homeTitleField,
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: l10n.entryTitleHint,
          labelText: l10n.entryTitleLabel,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          // Task 7.1 — alpha 0.75 to meet WCAG 1.4.3 AA contrast.
          hintStyle: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant.withValues(alpha: 0.75),
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}
