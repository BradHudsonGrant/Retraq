import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../utils/text_input_formatters.dart';
import '../../widgets/atoms/composer_surface.dart';
import '../../widgets/atoms/glow_box.dart';
import '../../widgets/atoms/retraq_button.dart';

/// The main journal text input area with optional title, AM/PM toggle,
/// and save button.
///
/// Subtle bleeding-edge polish (writing context — protect focus):
///   • Soft border glow that fades in on focus, fades out on blur.
///   • Save button gets a primary-coloured glow halo when there's something
///     to save. One-shot transitions only — never a continuous pulse — so
///     `pumpAndSettle` still converges in widget tests.
class JournalTextArea extends StatefulWidget {
  const JournalTextArea({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.isSaving,
    required this.onSave,
    this.topRightWidget,
    this.topLeftWidget,
    this.enterToSave = false,
    this.bulletPoints = false,
    this.minLines = 6,
    this.maxLines = 8,
    this.textFieldKey,
    this.saveButtonKey,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool isSaving;
  final VoidCallback onSave;
  final Widget? topRightWidget;

  /// Optional chip/control painted inside the top-left of the input.
  /// Mirrors [topRightWidget] which hosts the AM/PM toggle; the home
  /// screen uses this slot for the date-override chip so "setting the
  /// date for this traq" sits right next to where the user types.
  final Widget? topLeftWidget;
  final bool enterToSave;
  final bool bulletPoints;
  final int minLines;
  final int maxLines;

  /// Optional key for the underlying `TextField`. Plumbed through so that
  /// tests can target the input directly without reaching through multiple
  /// layers of decorations and animation wrappers.
  final Key? textFieldKey;

  /// Optional key for the `RetraqButton` save control. Same rationale as
  /// [textFieldKey] — avoids having to crawl the widget tree under the glow
  /// halo / scale wrappers.
  final Key? saveButtonKey;

  @override
  State<JournalTextArea> createState() => _JournalTextAreaState();
}

class _JournalTextAreaState extends State<JournalTextArea> {
  bool _hasFocus = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
    _hasFocus = widget.focusNode.hasFocus;
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant JournalTextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    final hasFocus = widget.focusNode.hasFocus;
    if (hasFocus != _hasFocus) {
      setState(() => _hasFocus = hasFocus);
    }
  }

  void _onTextChanged() {
    if (!mounted) return;
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;
    final reduceMotion = AppMotion.reduce(context);

    final textField = TextField(
      key: widget.textFieldKey,
      controller: widget.controller,
      focusNode: widget.focusNode,
      textCapitalization: TextCapitalization.sentences,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      style: tt.bodyLarge,
      scrollPadding: const EdgeInsets.only(bottom: 80),
      onTap: () {
        if (widget.bulletPoints && widget.controller.text.isEmpty) {
          widget.controller.value = const TextEditingValue(
            text: '• ',
            selection: TextSelection.collapsed(offset: 2),
          );
        }
      },
      inputFormatters: [
        if (widget.enterToSave) EnterToSaveFormatter(onEnter: widget.onSave),
        if (!widget.enterToSave && widget.bulletPoints) BulletPointFormatter(),
      ],
      decoration: InputDecoration(
        // hint-only: the floating label vertical metric doesn't match
        // the text-entry baseline, so tapping in made the cursor jump
        // down a few px from where the resting label sat. Swap to a
        // dual-mode hint so the baseline stays fixed — "Tap to traq"
        // at rest, the dynamic prompt ("How was today?" etc.) while
        // focused. Both render via hintText so the cursor never moves.
        hintText: _hasFocus || _hasText
            ? (widget.bulletPoints ? '• ${widget.hint}' : widget.hint)
            : l10n.journalEntryLabel,
        // Previously alpha 0.55 on light surface ~3.5:1,
        // failing WCAG 1.4.3 (4.5:1 minimum for body-size text). 0.75
        // raises the composited contrast comfortably above 4.5:1
        // while keeping the hint visually subordinate to typed text.
        hintStyle: tt.bodyLarge?.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.75),
        ),
        contentPadding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          // Leave room at the top for any topLeftWidget / topRightWidget
          // chips so they don't overlap the caret or floating label.
          (widget.topRightWidget != null || widget.topLeftWidget != null)
              ? 48
              : AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );

    // Save button + glow halo. Halo grows when there is text to save and
    // fades back out when the field is empty. Opacity rides a
    // TweenAnimationBuilder so the transition is smooth without an infinite
    // ticker — pumpAndSettle still converges.
    final saveButton = RetraqButton(
      key: widget.saveButtonKey,
      label: widget.isSaving ? l10n.saving : l10n.saveEntry,
      icon: Icons.done_all,
      onPressed: widget.isSaving ? null : widget.onSave,
    );

    final saveTarget = (_hasText && !widget.isSaving) ? 0.55 : 0.0;
    final Widget saveButtonWithGlow =
        reduceMotion
            ? saveButton
            : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: saveTarget),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              builder: (context, glow, child) {
                return GlowBox(
                  color: cs.primary,
                  glowOpacity: glow,
                  blurRadius: 26,
                  spreadRadius: 2,
                  borderRadius: AppSpacing.borderRadiusFull,
                  child: child!,
                );
              },
              child: saveButton,
            );

    final body = Stack(
      children: [
        textField,
        if (widget.topLeftWidget != null)
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: widget.topLeftWidget!,
          ),
        if (widget.topRightWidget != null)
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: widget.topRightWidget!,
          ),
        Positioned(
          bottom: AppSpacing.md,
          right: AppSpacing.md,
          child: saveButtonWithGlow,
        ),
      ],
    );

    // ComposerSurface carries the focus-responsive border + halo + the
    // recessed `surfaceContainerLow` fill. TitleField wraps in the
    // same atom so focus travel between the two fields reads as one
    // continuous composer.
    return ComposerSurface(focusNode: widget.focusNode, child: body);
  }
}
