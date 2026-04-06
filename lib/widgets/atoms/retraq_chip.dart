import 'package:flutter/material.dart';

/// Small pill-shaped tag/badge used for date labels, hashtags, etc.
/// Matches the "Yesterday", "Tuesday", "#Hyperfocus" pills from prototypes.
class RetraqChip extends StatelessWidget {
  const RetraqChip({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? cs.surfaceContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          color: textColor ?? cs.onSurfaceVariant,
        ),
      ),
    ));
  }
}
