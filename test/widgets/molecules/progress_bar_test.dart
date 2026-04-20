// ignore_for_file: prefer_single_quotes

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/l10n/app_localizations.dart';
import 'package:retraq/widgets/molecules/progress_bar.dart';

import '../../test_helpers.dart';

/// extracted ProgressBar molecule needs direct coverage
/// now that it lives outside home_screen.dart. Collapses to
/// SizedBox.shrink while weekCount < 1 so an empty placeholder card
/// doesn't hang above the composer on a blank week.
void main() {
  testWidgets(
    'weekCount=null collapses (no card, no icons)',
    (tester) async {
      await tester.pumpWidget(wrapWidget(
        const ProgressBar(weekCount: null),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.local_fire_department), findsNothing);
      expect(find.byIcon(Icons.edit_note), findsNothing);
    },
  );

  testWidgets(
    'weekCount=0 collapses — empty card would draw the eye for nothing',
    (tester) async {
      await tester.pumpWidget(wrapWidget(
        const ProgressBar(weekCount: 0),
      ));
      await tester.pump();

      final l10n = await L10n.delegate.load(const Locale('en'));
      expect(find.text(l10n.progressWeekCount(0)), findsNothing);
      expect(find.byIcon(Icons.local_fire_department), findsNothing);
      expect(find.byIcon(Icons.edit_note), findsNothing);
    },
  );

  testWidgets(
    'weekCount>0 shows count + flame icon',
    (tester) async {
      await tester.pumpWidget(wrapWidget(
        const ProgressBar(weekCount: 3),
      ));
      await tester.pump();

      final l10n = await L10n.delegate.load(const Locale('en'));
      expect(find.text(l10n.progressWeekCount(3)), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    },
  );

  testWidgets(
    'singular vs plural: weekCount=1 vs weekCount=2 diverge',
    (tester) async {
      // weekCount=1 → "1 traq this week — keep going!"
      // weekCount=2 → "2 traqs this week — keep going!" (ICU plural)
      // Pins that the ARB ICU plural rules continue to resolve.
      await tester.pumpWidget(wrapWidget(
        const ProgressBar(weekCount: 1),
      ));
      await tester.pump();

      final l10n = await L10n.delegate.load(const Locale('en'));
      final singular = l10n.progressWeekCount(1);
      final plural = l10n.progressWeekCount(2);

      expect(singular, isNot(plural),
          reason:
              'ICU plural form must differ between 1 and 2. If the '
              'ARB key gets simplified away from a plural form this '
              'test will catch it.');
      expect(find.text(singular), findsOneWidget);
    },
  );

  testWidgets(
    'bionicReadingEnabled=true does not crash',
    (tester) async {
      // BionicText swaps typography for partial-bold emphasis when
      // enabled. Smoke-check that the flag propagates without
      // exception; the visual output itself is covered by
      // bionic_text_test.dart at the atom layer.
      await tester.pumpWidget(wrapWidget(
        const ProgressBar(
          weekCount: 5,
          bionicReadingEnabled: true,
        ),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
      final l10n = await L10n.delegate.load(const Locale('en'));
      expect(find.text(l10n.progressWeekCount(5)), findsOneWidget);
    },
  );
}
