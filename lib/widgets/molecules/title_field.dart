import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../../utils/test_keys.dart';
import '../atoms/composer_surface.dart';

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
class TitleField extends StatefulWidget {
  const TitleField({
    super.key,
    required this.controller,
    this.nextFocusNode,
  });

  final TextEditingController controller;

  /// Focus target for the Enter / "Next" keyboard action. When supplied,
  /// submitting the title moves focus to this node (the journal body)
  /// so users can type the title, press Enter, and keep writing without
  /// reaching for the screen. Null → Enter does nothing special.
  final FocusNode? nextFocusNode;

  @override
  State<TitleField> createState() => _TitleFieldState();
}

class _TitleFieldState extends State<TitleField> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    // ComposerSurface carries the focus-responsive border + halo so
    // this field reads as one with JournalTextArea — see that atom
    // for the shared treatment.
    return ComposerSurface(
      focusNode: _focus,
      child: TextField(
        key: TestKeys.homeTitleField,
        controller: widget.controller,
        focusNode: _focus,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: widget.nextFocusNode != null
            ? TextInputAction.next
            : TextInputAction.done,
        onSubmitted: widget.nextFocusNode == null
            ? null
            : (_) => widget.nextFocusNode!.requestFocus(),
        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          // hint-only (no labelText): the floating label centers
          // vertically at a different offset than the text-entry baseline,
          // which made the cursor visibly jump when the user tapped in.
          // Hint copy sits at the same baseline as typed text, so the
          // field feels stable on focus.
          hintText: l10n.entryTitleHint,
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
