import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sincethen/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SinceThen E2E Test', () {
    testWidgets('Verify Universal Header and App Navigation',
        (tester) async {
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
      
      // 2. We should start on the Journal tab
      expect(find.textContaining('TL;DR'), findsWidgets);

      // 3. Navigate to Recap Tab
      final recapTab = find.text('Recap');
      await tester.tap(recapTab);
      await tester.pumpAndSettle();

      // 4. Verify we are on Recap Screen
      expect(find.text('Week'), findsWidgets);
      expect(find.text('Month'), findsWidgets);

      // 5. Ensure AppBar is still there natively (not doubled)
      expect(find.byType(AppBar), findsOneWidget);

      // 6. Navigate to Settings Tab
      final settingsTab = find.text('Settings');
      await tester.tap(settingsTab);
      await tester.pumpAndSettle();

      // 7. Verify we are on Settings Screen
      expect(find.text('Appearance'), findsOneWidget);
    });
  });
}
