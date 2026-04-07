import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/screens/onboarding/age_gate_page.dart';

import '../../test_helpers.dart';

/// Thin stateful harness so we can flip [AgeGatePage.isDenied] from the
/// test when the under-13 button is tapped, mirroring how
/// [OnboardingScreen] drives the real widget.
class _AgeGateHarness extends StatefulWidget {
  const _AgeGateHarness();

  @override
  State<_AgeGateHarness> createState() => _AgeGateHarnessState();
}

class _AgeGateHarnessState extends State<_AgeGateHarness> {
  bool _denied = false;

  @override
  Widget build(BuildContext context) {
    return AgeGatePage(
      onConfirm: () {},
      onDeny: () => setState(() => _denied = true),
      isDenied: _denied,
    );
  }
}

void main() {
  group('AgeGatePage (COPPA)', () {
    testWidgets(
      'tapping "I am under 13" shows denial screen with no retry/mistake copy',
      (tester) async {
        await tester.pumpWidget(wrapWidget(const _AgeGateHarness()));
        await tester.pumpAndSettle();

        // Sanity: the initial age gate is rendered.
        expect(find.text('Before we begin'), findsOneWidget);
        expect(find.text('I am 13 or older'), findsOneWidget);
        expect(find.text('I am under 13'), findsOneWidget);

        // Tap the neutral denial option.
        await tester.tap(find.text('I am under 13'));
        await tester.pumpAndSettle();

        // Denial screen is now visible.
        expect(find.text('Sorry!'), findsOneWidget);
        expect(
          find.textContaining('13 years or older'),
          findsOneWidget,
          reason: 'Denial copy should explain the age requirement.',
        );
        expect(
          find.textContaining('parent or guardian'),
          findsOneWidget,
          reason:
              'Neutral, non-actionable guidance should point users to a '
              'parent/guardian rather than a retry button.',
        );

        // COPPA: there must be NO widget anywhere on the denial screen
        // that nudges the user to re-declare their age.
        expect(
          find.textContaining('mistake', findRichText: true),
          findsNothing,
          reason:
              'The denial screen must not offer an "I made a mistake" '
              'escape hatch — FTC guidance requires a neutral age gate.',
        );
        expect(
          find.textContaining('Mistake', findRichText: true),
          findsNothing,
        );
        expect(
          find.textContaining('retry', findRichText: true),
          findsNothing,
        );
        expect(
          find.textContaining('Retry', findRichText: true),
          findsNothing,
        );
        expect(
          find.textContaining('Try again', findRichText: true),
          findsNothing,
        );

        // No interactive buttons should remain on the denial screen.
        expect(find.byType(TextButton), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
        expect(find.byType(ElevatedButton), findsNothing);
      },
    );
  });
}
