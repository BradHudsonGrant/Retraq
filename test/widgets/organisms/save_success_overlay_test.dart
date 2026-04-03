import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sincethen/widgets/organisms/save_success_overlay.dart';

import '../../test_helpers.dart';

void main() {
  group('SaveSuccessOverlay', () {
    testWidgets('renders checkmark icon', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(wrapWidget(
        SaveSuccessOverlay(onDismissed: () => dismissed = true),
      ));

      await tester.pump();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Pump through all pending timers to avoid "Timer still pending" error.
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('shows "Entry saved" text', (tester) async {
      await tester.pumpWidget(wrapWidget(
        SaveSuccessOverlay(onDismissed: () {}),
      ));

      await tester.pump();
      expect(find.text('Entry saved'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('shows "Nice one" confirmation text', (tester) async {
      await tester.pumpWidget(wrapWidget(
        SaveSuccessOverlay(onDismissed: () {}),
      ));

      await tester.pump();
      expect(find.textContaining('Nice one'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('shows milestone message when provided', (tester) async {
      await tester.pumpWidget(wrapWidget(
        SaveSuccessOverlay(
          onDismissed: () {},
          milestoneMessage: 'Your very first entry!',
        ),
      ));

      await tester.pump();
      expect(find.text('Your very first entry!'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('does not show milestone message when null', (tester) async {
      await tester.pumpWidget(wrapWidget(
        SaveSuccessOverlay(onDismissed: () {}),
      ));

      await tester.pump();
      expect(find.text('Your very first entry!'), findsNothing);

      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('onDismissed fires after animation completes', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(wrapWidget(
        SaveSuccessOverlay(onDismissed: () => dismissed = true),
      ));

      // Pump through the full animation sequence:
      // 150ms haptic delay + 1000ms hold + 400ms exit
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(dismissed, isFalse);

      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 500));
      expect(dismissed, isTrue);

      // Flush any remaining timers
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    testWidgets('GestureDetector is present for tap-to-dismiss',
        (tester) async {
      await tester.pumpWidget(wrapWidget(
        SaveSuccessOverlay(onDismissed: () {}),
      ));

      await tester.pump();

      // Verify the tap-to-dismiss GestureDetector exists
      expect(find.byType(GestureDetector), findsOneWidget);

      // Verify the dismiss semantics label is present
      expect(find.bySemanticsLabel('Dismiss'), findsOneWidget);

      // Flush remaining timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('respects reduceMotion — jumps to final state',
        (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: SaveSuccessOverlay(
                onDismissed: () => dismissed = true,
              ),
            ),
          ),
        ),
      );

      // With reduce motion, entry animation jumps to 1.0 immediately.
      await tester.pump();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Pump through the hold + exit
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(dismissed, isTrue);

      // Flush remaining timers
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });
  });
}
