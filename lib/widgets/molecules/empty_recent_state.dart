import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';

/// Task 2.13 — Empty state shown on Home when neither yesterday nor the
/// day-before have any traqs. Replaces a flat one-line placeholder with
/// a warmer composition: a soft iconographic mark, a short headline,
/// and a low-pressure body copy that echoes the brand voice.
///
/// Uses a Material icon rather than a custom SVG so we do not block on
/// illustration work (see Epic 13). When a final illustration ships,
/// swap `Icon(Icons.edit_note_rounded)` for the asset.
class EmptyRecentState extends StatelessWidget {
  const EmptyRecentState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Semantics(
        container: true,
        label: '${l10n.emptyRecentHeadline}. ${l10n.emptyRecentBody}',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 36,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.emptyRecentHeadline,
              textAlign: TextAlign.center,
              style: tt.titleMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.emptyRecentBody,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
