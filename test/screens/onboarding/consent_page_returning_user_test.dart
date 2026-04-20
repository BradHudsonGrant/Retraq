// ignore_for_file: prefer_single_quotes

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/l10n/app_localizations.dart';
import 'package:retraq/screens/onboarding/consent_page.dart';

import '../../test_helpers.dart';

/// returning-user detection on the consent page.
///
/// When a cross-install consent marker is observed in hardened
/// secure storage, OnboardingScreen skips the 3 marketing intro
/// pages and lands directly on the consent page with
/// `isReturningUser: true`. This file pins the two user-visible
/// consequences of that flag:
///
/// 1. The headline swaps from "Almost there!" to "Welcome back".
/// 2. A subtitle appears explaining why consent is still required.
///
/// The underlying re-consent mechanics (checkbox states, legal-doc
/// navigation) are identical regardless of the flag — this file
/// only covers the returning-user delta, not the full consent flow.
void main() {
  testWidgets('fresh-install path keeps the "Almost there!" headline',
      (tester) async {
    await tester.pumpWidget(wrapScrollable(ConsentPage(
      privacyAccepted: false,
      termsAccepted: false,
      healthAccepted: false,
      onPrivacyChanged: (_) {},
      onTermsChanged: (_) {},
      onHealthChanged: (_) {},
      // isReturningUser defaults to false.
    )));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Headline is the original onboarding title.
    expect(find.text('Almost there!'), findsOneWidget,
        reason:
            'Fresh-install path must keep the "Almost there!" headline so '
            'first-time users see the completion cue rather than "Welcome '
            'back".');

    // Subtitle is NOT shown on fresh install.
    final l10n = await L10n.delegate.load(const Locale('en'));
    expect(find.text(l10n.welcomeBackSubtitle), findsNothing,
        reason:
            'Fresh-install path must not show the reinstall-context '
            'subtitle.');
  });

  testWidgets('returning-user path swaps headline + shows subtitle',
      (tester) async {
    await tester.pumpWidget(wrapScrollable(ConsentPage(
      privacyAccepted: false,
      termsAccepted: false,
      healthAccepted: false,
      onPrivacyChanged: (_) {},
      onTermsChanged: (_) {},
      onHealthChanged: (_) {},
      isReturningUser: true,
    )));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final l10n = await L10n.delegate.load(const Locale('en'));

    expect(find.text(l10n.welcomeBackTitle), findsOneWidget,
        reason: 'Returning-user path must show "Welcome back" headline.');
    expect(find.text('Almost there!'), findsNothing,
        reason: 'Returning-user path must NOT fall back to the fresh-'
            'install headline.');

    expect(find.text(l10n.welcomeBackSubtitle), findsOneWidget,
        reason:
            'Returning-user subtitle explaining consent is still required '
            'must be visible.');
  });

  testWidgets('returning-user flag does NOT auto-tick consent checkboxes',
      (tester) async {
    // The cross-install marker is a UX shortcut, not a consent bypass —
    // pin the compliance invariant that checkboxes still start unchecked.
    var privacyChanges = 0;
    await tester.pumpWidget(wrapScrollable(ConsentPage(
      privacyAccepted: false,
      termsAccepted: false,
      healthAccepted: false,
      onPrivacyChanged: (_) => privacyChanges += 1,
      onTermsChanged: (_) {},
      onHealthChanged: (_) {},
      isReturningUser: true,
    )));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Returning-user flag must not have fired any checkbox change
    // callbacks — the page respects the initial `false` state.
    expect(privacyChanges, 0,
        reason:
            'isReturningUser must NOT auto-accept consent. Any such '
            'bypass would violate GDPR Art. 7 and PIPEDA Principle 3 '
            '(meaningful consent on every install).');
  });
}
