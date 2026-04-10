import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:retraq/main.dart' as app;
import 'package:retraq/utils/test_keys.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Retraq E2E Test', () {
    testWidgets('Verify Universal Header and App Navigation', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Handle AppLock / Onboarding (Fresh Install support)
      final skipBtn = find.text('Skip');
      if (skipBtn.evaluate().isNotEmpty) {
        await tester.tap(skipBtn);
        await tester.pumpAndSettle();
      }

      // 1. Check for the SVG Logo in the persistent AppBar
      expect(find.byType(SvgPicture), findsWidgets);

      // 2. We should start on the Journal tab — verify via the nav key
      expect(find.byKey(TestKeys.navJournalTab), findsOneWidget);
      expect(find.textContaining('TL;DR'), findsWidgets);

      // 3. Navigate to Recap tab
      await tester.tap(find.byKey(TestKeys.navRecapTab));
      await tester.pumpAndSettle();

      // 4. Verify we're on Recap: the Week/Month toggle should exist
      expect(find.byKey(TestKeys.recapWeekMonthToggle), findsOneWidget);
      expect(find.byKey(TestKeys.recapSearchToggle), findsOneWidget);

      // 5. Navigate to Settings tab
      await tester.tap(find.byKey(TestKeys.navSettingsTab));
      await tester.pumpAndSettle();

      // 6. Verify we're on Settings: the appearance section should exist
      expect(find.byKey(TestKeys.settingsAppearanceSection), findsOneWidget);
      expect(find.byKey(TestKeys.settingsPreferencesSection), findsOneWidget);

      // 7. Hop back to Journal
      await tester.tap(find.byKey(TestKeys.navJournalTab));
      await tester.pumpAndSettle();
      expect(find.byKey(TestKeys.homeEntryField), findsOneWidget);
      expect(find.byKey(TestKeys.homeSaveButton), findsOneWidget);
    });
  });
}
