import 'package:flutter/material.dart';

/// Breakpoint for tablet two-pane layouts.
/// Set to 840dp to ensure enough space for two content panes.
const double kTabletBreakpoint = 840;

/// Returns true if the available width supports a two-pane layout.
bool isTablet(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= kTabletBreakpoint;
}

/// A two-pane layout for tablet screens. Shows [left] and [right] side by side
/// with a configurable split ratio. On phone-width screens, shows only [child].
class AdaptiveTwoPane extends StatelessWidget {
  final Widget left;
  final Widget right;

  /// Fraction of width for the left pane (0.0-1.0). Default 0.45.
  final double leftFraction;

  const AdaptiveTwoPane({
    super.key,
    required this.left,
    required this.right,
    this.leftFraction = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: (leftFraction * 100).round(),
          child: left,
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: ((1 - leftFraction) * 100).round(),
          child: right,
        ),
      ],
    );
  }
}
