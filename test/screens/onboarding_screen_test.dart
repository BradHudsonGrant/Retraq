import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sincethen/screens/onboarding_screen.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> passAgeGate(WidgetTester tester) async {
    await tester.tap(find.text('I am 13 or older'));
    await tester.pumpAndSettle();
  }

  Future<void> navigateToConsentPage(WidgetTester tester) async {
    await passAgeGate(tester);
    // Navigate through 3 info pages to reach consent page
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }

  group('OnboardingScreen', () {
    group('age gate', () {
      testWidgets('renders age gate as first page', (tester) async {
        await tester.pumpWidget(wrapScreen(
          OnboardingScreen(onComplete: () {}),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Before we begin'), findsOneWidget);
        expect(find.text('SinceThen is designed for users\naged 13 and older.'), findsOneWidget);
        expect(find.text('I am 13 or older'), findsOneWidget);
        expect(find.text('I am under 13'), findsOneWidget);
      });

      testWidgets('hides dots and Next button on age gate page', (tester) async {
        await tester.pumpWidget(wrapScreen(
          OnboardingScreen(onComplete: () {}),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Next'), findsNothing);
        expect(find.text('Skip'), findsNothing);
      });

      testWidgets('I am 13 or older advances to first info page', (tester) async {
        await tester.pumpWidget(wrapScreen(
          OnboardingScreen(onComplete: () {}),
        ));
        await tester.pumpAndSettle();

        await passAgeGate(tester);

        expect(find.text('Your day,\nyour words.'), findsOneWidget);
      });

      testWidgets('I am under 13 shows persistent block', (tester) async {
        await tester.pumpWidget(wrapScreen(
          OnboardingScreen(onComplete: () {}),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('I am under 13'));
        await tester.pumpAndSettle();

        // Shows blocked state — sorry message and no confirm button
        expect(find.text('Sorry!'), findsOneWidget);
        expect(find.text('I am 13 or older'), findsNothing);
        expect(find.text('I am under 13'), findsNothing);
      });
    });

    testWidgets('renders first page content', (tester) async {
      await tester.pumpWidget(wrapScreen(
        OnboardingScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      await passAgeGate(tester);

      expect(find.text('Your day,\nyour words.'), findsOneWidget);
      expect(find.text('No templates. No pressure.\nJust jot down the highlights.'), findsOneWidget);
    });

    testWidgets('no Skip button after age gate', (tester) async {
      await tester.pumpWidget(wrapScreen(
        OnboardingScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      await passAgeGate(tester);

      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('shows Next button on first page', (tester) async {
      await tester.pumpWidget(wrapScreen(
        OnboardingScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      await passAgeGate(tester);

      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Next advances to second page', (tester) async {
      await tester.pumpWidget(wrapScreen(
        OnboardingScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      await passAgeGate(tester);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Look back\nwithout stress.'), findsOneWidget);
    });

    testWidgets('shows Get Started on consent page', (tester) async {
      await tester.pumpWidget(wrapScreen(
        OnboardingScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      await navigateToConsentPage(tester);

      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Almost there!'), findsOneWidget);
    });

    testWidgets('Get Started disabled until consent checkboxes checked', (tester) async {
      var completed = false;
      await tester.pumpWidget(wrapScreen(
        OnboardingScreen(onComplete: () => completed = true),
      ));
      await tester.pumpAndSettle();

      await navigateToConsentPage(tester);

      // Get Started should be disabled
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      expect(completed, false);

      // Check all three checkboxes (ensureVisible needed after 48dp touch targets)
      final checkboxes = find.byType(Checkbox);
      for (var i = 0; i < 3; i++) {
        await tester.ensureVisible(checkboxes.at(i));
        await tester.tap(checkboxes.at(i));
        await tester.pump();
      }

      // Now Get Started should work — triggers notification pre-prompt dialog
      await tester.ensureVisible(find.text('Get Started'));
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Dismiss the notification pre-prompt dialog
      final notNow = find.text('Not now');
      if (notNow.evaluate().isNotEmpty) {
        await tester.tap(notNow);
        await tester.pumpAndSettle();
      }
      expect(completed, true);
    });

    testWidgets('has 4 page indicator dots', (tester) async {
      await tester.pumpWidget(wrapScreen(
        OnboardingScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      await passAgeGate(tester);

      // There are exactly 4 AnimatedContainer dots (3 info + 1 consent)
      final dots = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(dots.length, 4);
    });

    testWidgets('swipe gesture advances pages', (tester) async {
      await tester.pumpWidget(wrapScreen(
        OnboardingScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      await passAgeGate(tester);

      // Swipe left to go to page 2
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 800);
      await tester.pumpAndSettle();

      expect(find.text('Look back\nwithout stress.'), findsOneWidget);
    });

    testWidgets('all three info pages have correct body text', (tester) async {
      await tester.pumpWidget(wrapScreen(
        OnboardingScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      await passAgeGate(tester);

      // Page 1
      expect(find.text('No templates. No pressure.\nJust jot down the highlights.'), findsOneWidget);

      // Page 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('A simple calendar shows\nwhat you captured each day.'), findsOneWidget);

      // Page 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Everything stays on your phone.\nNo account needed. Ever.'), findsOneWidget);
    });

    testWidgets('consent page shows health disclaimer', (tester) async {
      await tester.pumpWidget(wrapScreen(
        OnboardingScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      await navigateToConsentPage(tester);

      expect(find.textContaining('not a medical or therapeutic tool'), findsOneWidget);
      expect(find.textContaining('988'), findsOneWidget);
    });

    testWidgets('consent page shows privacy and terms checkboxes', (tester) async {
      await tester.pumpWidget(wrapScreen(
        OnboardingScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      await navigateToConsentPage(tester);

      expect(find.byType(Checkbox), findsNWidgets(3));
      expect(find.text('I acknowledge the Health Disclaimer'), findsOneWidget);
      expect(find.text('I have read and agree to the Privacy Policy'), findsOneWidget);
      expect(find.text('I agree to the Terms of Use'), findsOneWidget);
    });

    testWidgets('renders logo SVG', (tester) async {
      await tester.pumpWidget(wrapScreen(
        OnboardingScreen(onComplete: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsOneWidget);
    });
  });
}
