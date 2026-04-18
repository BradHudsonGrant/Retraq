import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_motion.dart';
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
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focus.hasFocus != _hasFocus) {
      setState(() => _hasFocus = _focus.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Mirror JournalTextArea's focus treatment so the title and body
    // read as one unified composer: primary-tinted border + soft outer
    // halo when focused, muted outline when resting. Animation duration
    // matches JournalTextArea (240ms) so focus travel between the two
    // fields feels continuous rather than staggered.
    final borderColor = _hasFocus
        ? cs.primary.withValues(alpha: 0.55)
        : cs.outlineVariant.withValues(alpha: 0.3);
    final List<BoxShadow> shadow = [
      if (_hasFocus && !reduceMotion)
        BoxShadow(
          color: cs.primary.withValues(alpha: 0.22),
          blurRadius: 22,
          spreadRadius: 1,
          blurStyle: BlurStyle.outer,
        ),
    ];

    return AnimatedContainer(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
      curve: AppMotion.standard,
      // Match JournalTextArea's recessed-well surface so the title field
      // reads as part of the same composer, not a separate raised card.
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(color: borderColor, width: _hasFocus ? 1.4 : 1.0),
        boxShadow: shadow,
      ),
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
