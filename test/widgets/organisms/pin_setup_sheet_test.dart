@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sincethen/widgets/organisms/pin_setup_sheet.dart';
import 'package:sincethen/widgets/molecules/number_pad.dart';

import '../../test_helpers.dart';

void main() {
  // PinSetupSheet is tall (number pad + dots + buttons). We render it
  // directly inside a scrollable scaffold rather than as a bottom sheet
  // to avoid overflow in the 600×800 test viewport.

  Widget wrap() => const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PinSetupSheet(),
          ),
        ),
      );

  group('PinSetupSheet', () {
    testWidgets('shows "Set a PIN" title', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text('Set a PIN'), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('shows "Choose a 4-digit PIN" subtitle', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text('Choose a 4-digit PIN'), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('shows NumberPad and PinDots widgets', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.byType(NumberPad), findsOneWidget);
      expect(find.byType(PinDots), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('shows Cancel button', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);

      await flushDriftTimers(tester);
    });

    testWidgets('entering 4 digits advances to confirm step', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      // Enter 4 digits (not in denylist)
      for (final d in ['3', '7', '9', '2']) {
        await tester.tap(find.text(d));
        await tester.pump();
      }

      // The auto-advance triggers after a 200ms Future.delayed
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Confirm PIN'), findsOneWidget);
      expect(find.text('Enter the same PIN again'), findsOneWidget);

      await flushDriftTimers(tester);
    });
  });
}
