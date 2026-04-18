import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../widgets/settings_provider.dart';
import '../../services/ai/recap_ai_provider.dart' show parseRecapBullets;
import '../../services/recap_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/atoms/bionic_text.dart';

/// Displays the weekly recap summary card.
///
/// Styled to visually match the day cards in [WeekDayList] — same
/// `surfaceContainerLow` fill, `borderRadiusXl` corners, `AppSpacing.lg`
/// padding and full width — so the entire week scroll reads as a single
/// rhythm. The accent here is a tinted left border + primary-coloured
/// title rather than a separate Material Card with its own elevation.
///
/// When [isGenerating] is true (on-device AI recap is in flight), the
/// observation text is replaced with a subtle three-line shimmer plus a
/// gentle pulse on the card border — signalling "something's happening"
/// without blocking the other stats. When generation finishes the card
/// cross-fades the new observation in smoothly via [AnimatedSwitcher].
class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({
    super.key,
    required this.summary,
    this.isGenerating = false,
  });

  final WeeklySummary summary;
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      // "Featured card" treatment — deliberately distinct from the
      // regular content tier so the weekly recap reads as the hero
      // of the Recap screen:
      //   • Dark recessed surface (surfaceContainerLow) matching the
      //     Traq input well, inverting the normal card→content
      //     hierarchy so the recap feels like a "pocket" of its own.
      //   • Full 1.5px primary border on all four sides — the green
      //     now wraps the card instead of living only on the left
      //     edge, giving it an unmistakable brand frame.
      //   • Soft primary-tinted glow so the card appears to give off
      //     a faint halo, reinforcing the "hero tile" read without
      //     shouting.
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.75),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGenerating ? Icons.auto_awesome_outlined : Icons.auto_awesome,
                size: 16,
                color: cs.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                isGenerating ? 'Generating recap…' : 'Weekly Recap',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // AnimatedSwitcher cross-fades the shimmer → real content when
          // the AI call resolves, so the transition feels like one
          // smooth motion rather than text popping in.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: isGenerating
                ? _ShimmerLines(
                    key: const ValueKey('generating'),
                    color: cs.onSurface,
                    style: tt.bodyMedium,
                  )
                : _ObservationContent(
                    key: ValueKey('obs:${summary.observation}'),
                    observation: summary.observation,
                  ),
          ),
          if (summary.totalEntries > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.edit_note,
                  size: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${summary.totalEntries} entries \u00b7 ${summary.activeDays} days \u00b7 ${summary.preferredTime}',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    // While generating, pulse the primary border shadow gently so the
    // user's eye is drawn to the card as it works. Once text arrives,
    // the pulse stops — the static glow alone reads as "done".
    if (!isGenerating) return card;
    return card
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .custom(
          duration: const Duration(milliseconds: 1400),
          begin: 0,
          end: 1,
          builder: (context, value, child) {
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppSpacing.borderRadiusXl,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.10 + 0.18 * value),
                    blurRadius: 10 + 18 * value,
                    spreadRadius: value * 0.5,
                  ),
                ],
              ),
              child: child,
            );
          },
        );
  }
}

/// Renders the observation either as a consistent bullet list (the AI
/// path, where the prompt forces "- " bullets) or as a single paragraph
/// (the template fallback path). Bullets fade in with a slight stagger
/// so the week reads like it's being narrated, not pasted.
class _ObservationContent extends StatelessWidget {
  const _ObservationContent({super.key, required this.observation});

  final String observation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bionicEnabled =
        SettingsProvider.maybeOf(context)?.bionicReadingEnabled ?? false;

    final bullets = parseRecapBullets(observation);

    // Template observation or AI that happened to return one prose
    // sentence — render as a paragraph.
    if (bullets.length <= 1) {
      return BionicText(
        text: bullets.isEmpty ? observation : bullets.first,
        style: tt.bodyMedium?.copyWith(color: cs.onSurface, height: 1.4),
        enabled: bionicEnabled,
      );
    }

    // AI multi-bullet case — render as a list with a staggered fade-in.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < bullets.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          _BulletLine(
            text: bullets[i],
            style: tt.bodyMedium?.copyWith(color: cs.onSurface, height: 1.35),
            bionicEnabled: bionicEnabled,
            dotColor: cs.primary,
          )
              .animate()
              .fadeIn(
                duration: 260.ms,
                delay: Duration(milliseconds: 60 * i),
                curve: Curves.easeOut,
              )
              .slideY(
                begin: 0.12,
                end: 0,
                duration: 320.ms,
                delay: Duration(milliseconds: 60 * i),
                curve: Curves.easeOutCubic,
              ),
        ],
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({
    required this.text,
    required this.style,
    required this.bionicEnabled,
    required this.dotColor,
  });

  final String text;
  final TextStyle? style;
  final bool bionicEnabled;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Nudge the dot onto the first text baseline — a raw glyph
          // bullet sits too high because text has descent padding.
          padding: const EdgeInsets.only(top: 7, right: AppSpacing.sm),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ),
        Expanded(
          child: BionicText(
            text: text,
            style: style,
            enabled: bionicEnabled,
          ),
        ),
      ],
    );
  }
}

/// Three skeleton lines that shimmer from muted → primary-tinted → muted
/// on a loop. Roughly matches the height of a two-line observation so
/// layout doesn't jump when real text fades in.
class _ShimmerLines extends StatelessWidget {
  const _ShimmerLines({super.key, required this.color, required this.style});

  final Color color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lineHeight = (style?.fontSize ?? 14) * (style?.height ?? 1.4);
    final base = cs.onSurface.withValues(alpha: 0.10);
    final highlight = cs.primary.withValues(alpha: 0.22);

    Widget line({required double widthFraction, int delayMs = 0}) {
      return FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFraction,
        child: Container(
          height: lineHeight * 0.55,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      )
          .animate(
            onPlay: (c) => c.repeat(reverse: true),
            delay: Duration(milliseconds: delayMs),
          )
          .tint(color: highlight, duration: 900.ms, curve: Curves.easeInOut);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line(widthFraction: 0.92),
        SizedBox(height: lineHeight * 0.4),
        line(widthFraction: 0.78, delayMs: 150),
        SizedBox(height: lineHeight * 0.4),
        line(widthFraction: 0.55, delayMs: 300),
      ],
    );
  }
}
