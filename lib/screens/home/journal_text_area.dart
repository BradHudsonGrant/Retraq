import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../../utils/text_input_formatters.dart';
import '../../widgets/atoms/retraq_button.dart';

/// The main journal text input area with optional title, AM/PM toggle,
/// and save button.
class JournalTextArea extends StatelessWidget {
  const JournalTextArea({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.isSaving,
    required this.onSave,
    this.topRightWidget,
    this.enterToSave = false,
    this.bulletPoints = false,
    this.minLines = 6,
    this.maxLines = 8,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool isSaving;
  final VoidCallback onSave;
  final Widget? topRightWidget;
  final bool enterToSave;
  final bool bulletPoints;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.sentences,
            maxLines: maxLines,
            minLines: minLines,
            style: tt.bodyLarge,
            scrollPadding: const EdgeInsets.only(bottom: 80),
            onTap: () {
              if (bulletPoints && controller.text.isEmpty) {
                controller.value = const TextEditingValue(
                  text: '• ',
                  selection: TextSelection.collapsed(offset: 2),
                );
              }
            },
            inputFormatters: [
              if (enterToSave) EnterToSaveFormatter(onEnter: onSave),
              if (!enterToSave && bulletPoints) BulletPointFormatter(),
            ],
            decoration: InputDecoration(
              hintText: bulletPoints ? '• $hint' : hint,
              labelText: l10n.journalEntryLabel,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              hintStyle: tt.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.55),
              ),
              contentPadding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                topRightWidget != null ? 48 : AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
          if (topRightWidget != null)
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: topRightWidget!,
            ),
          Positioned(
            bottom: AppSpacing.md,
            right: AppSpacing.md,
            child: RetraqButton(
              label: isSaving ? l10n.saving : l10n.saveEntry,
              icon: Icons.done_all,
              onPressed: isSaving ? null : onSave,
            ),
          ),
        ],
      ),
    );
  }
}
