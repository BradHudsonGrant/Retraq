import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sincethen/screens/legal_screen.dart';
import 'package:sincethen/screens/reconsent_screen.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReconsentScreen', () {
    testWidgets('renders all three consent checkboxes', (tester) async {
      await tester.pumpWidget(wrapScreen(
        ReconsentScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNWidgets(3));
      expect(
        find.text('I have read and agree to the Privacy Policy'),
        findsOneWidget,
      );
      expect(
        find.text('I agree to the Terms of Use'),
        findsOneWidget,
      );
      expect(
        find.text('I have read and accept the Health Disclaimer'),
        findsOneWidget,
      );
    });

    testWidgets('renders Updated Policies heading', (tester) async {
      await tester.pumpWidget(wrapScreen(
        ReconsentScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Updated Policies'), findsOneWidget);
    });

    testWidgets('continue button is disabled until all checkboxes are checked',
        (tester) async {
      await tester.pumpWidget(wrapScreen(
        ReconsentScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      // Initially disabled
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      // Check first checkbox (privacy)
      await tester.tap(find.byType(Checkbox).at(0));
      await tester.pumpAndSettle();

      // Still disabled (only 1 of 3 checked)
      final button2 = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button2.onPressed, isNull);

      // Check second checkbox (terms)
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();

      // Still disabled (only 2 of 3 checked)
      final button3 = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button3.onPressed, isNull);

      // Check third checkbox (health disclaimer)
      await tester.tap(find.byType(Checkbox).at(2));
      await tester.pumpAndSettle();

      // Now enabled (all 3 checked)
      final button4 = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button4.onPressed, isNotNull);
    });

    testWidgets('tapping privacy link navigates to LegalScreen',
        (tester) async {
      await tester.pumpWidget(wrapScreen(
        ReconsentScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      // Tap the underlined text link for privacy policy
      await tester.tap(
        find.text('I have read and agree to the Privacy Policy'),
      );
      await tester.pumpAndSettle();

      // Should navigate to LegalScreen with Privacy Policy title
      expect(find.byType(LegalScreen), findsOneWidget);
      expect(find.text('Privacy Policy'), findsWidgets);
    });

    testWidgets('tapping terms link navigates to LegalScreen',
        (tester) async {
      await tester.pumpWidget(wrapScreen(
        ReconsentScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('I agree to the Terms of Use'));
      await tester.pumpAndSettle();

      expect(find.byType(LegalScreen), findsOneWidget);
      expect(find.text('Terms of Use'), findsWidgets);
    });

    testWidgets('tapping health disclaimer link navigates to LegalScreen',
        (tester) async {
      await tester.pumpWidget(wrapScreen(
        ReconsentScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('I have read and accept the Health Disclaimer'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LegalScreen), findsOneWidget);
      expect(find.text('Health & Wellness Disclaimer'), findsWidgets);
    });

    testWidgets('submitting calls onComplete', (tester) async {
      var completed = false;

      await tester.pumpWidget(wrapScreen(
        ReconsentScreen(onComplete: () => completed = true),
      ));
      await tester.pumpAndSettle();

      // Check all three checkboxes
      await tester.tap(find.byType(Checkbox).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).at(2));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('unchecking a checkbox disables the continue button again',
        (tester) async {
      await tester.pumpWidget(wrapScreen(
        ReconsentScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      // Check all three
      await tester.tap(find.byType(Checkbox).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).at(2));
      await tester.pumpAndSettle();

      // Should be enabled
      final button1 = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button1.onPressed, isNotNull);

      // Uncheck one
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();

      // Should be disabled again
      final button2 = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button2.onPressed, isNull);
    });
  });
}
