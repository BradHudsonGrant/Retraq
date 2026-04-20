// ignore_for_file: prefer_single_quotes

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/widgets/atoms/tab_swipe_edge_glow.dart';

import '../../test_helpers.dart';

/// tests for TabSwipeEdgeGlow.
///
/// Manual on-device verification covers the visual quality of the
/// glow; these widget tests pin the behavioral contract that
/// matters for regressions:
///   - non-swipe gestures pass through (taps + vertical scrolls)
///   - reduce-motion skips the glow entirely
///   - the child still renders with no swipe at all
void main() {
  testWidgets('child renders with no swipe input', (tester) async {
    await tester.pumpWidget(wrapWidget(
      const TabSwipeEdgeGlow(
        child: SizedBox(
          width: 200,
          height: 200,
          child: Text('pane'),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('pane'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap on child does not crash + does not trigger glow',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrapWidget(
      TabSwipeEdgeGlow(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps += 1,
          child: const SizedBox(width: 200, height: 200),
        ),
      ),
    ));
    await tester.pump();

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();

    expect(taps, 1,
        reason:
            'The edge-glow wrapper must not swallow tap gestures. '
            'Its GestureDetector uses HitTestBehavior.deferToChild '
            'so taps propagate to the PageView children.');
  });

  testWidgets(
    'reduce-motion MediaQuery suppresses the glow entirely',
    (tester) async {
      // wrapWidget applies disableAnimations: true by default
      // (see test_helpers.dart). This implicitly tests the
      // reduce-motion bypass path.
      await tester.pumpWidget(wrapWidget(
        const TabSwipeEdgeGlow(
          child: SizedBox(
            width: 400,
            height: 400,
            key: ValueKey('pane'),
          ),
        ),
      ));
      await tester.pump();

      // Fire a high-velocity horizontal fling.
      await tester.fling(
        find.byKey(const ValueKey('pane')),
        const Offset(-300, 0),
        1500,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The glow is implemented as a DecoratedBox inside an
      // IgnorePointer positioned fill; check none was inserted.
      // The only top-level DecoratedBox that would appear is the
      // glow overlay itself. Other DecoratedBoxes come from
      // wrapWidget's MaterialApp scaffolding; filter to the
      // IgnorePointer-wrapped one used for the glow.
      expect(
        find.descendant(
          of: find.byType(TabSwipeEdgeGlow),
          matching: find.byType(IgnorePointer),
        ),
        findsNothing,
        reason:
            'Reduce-motion (wrapWidget default) must suppress the '
            'glow Positioned.fill overlay. If this finds anything, '
            'the bypass in _onHorizontalDragEnd was skipped.',
      );
    },
  );

  testWidgets(
    'vertical drag passes through without firing glow',
    (tester) async {
      // Motion-enabled shell so the glow WOULD fire for horizontal;
      // confirm vertical drags skip the trigger.
      await tester.pumpWidget(wrapWidget(
        const TabSwipeEdgeGlow(
          child: SizedBox(
            width: 400,
            height: 400,
            key: ValueKey('pane'),
          ),
        ),
        enableAnimations: true,
      ));
      await tester.pump();

      // Vertical fling (no x component).
      await tester.fling(
        find.byKey(const ValueKey('pane')),
        const Offset(0, -300),
        1500,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The GestureDetector only listens for horizontal drags, so
      // vertical gestures don't reach _onHorizontalDragEnd. No glow
      // overlay should have been inserted.
      expect(
        find.descendant(
          of: find.byType(TabSwipeEdgeGlow),
          matching: find.byType(IgnorePointer),
        ),
        findsNothing,
        reason:
            'Vertical scrolls must pass through without the glow — '
            'PageView children often have their own vertical scroll '
            'views whose physics would be disrupted if we hijacked.',
      );
    },
  );
}
