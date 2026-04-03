import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sincethen/services/review_service.dart';

/// Mock the in_app_review plugin channel.
/// Tracks whether requestReview was called.
bool _reviewRequested = false;

void _mockInAppReview({bool available = true}) {
  _reviewRequested = false;
  const channel = MethodChannel('dev.britannio.in_app_review');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'isAvailable':
        return available;
      case 'requestReview':
        _reviewRequested = true;
        return null;
      default:
        return null;
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _mockInAppReview();
  });

  group('ReviewService.checkAndPrompt', () {
    test('does nothing when count is not 5', () async {
      await ReviewService.instance.checkAndPrompt(1);
      expect(_reviewRequested, false);

      await ReviewService.instance.checkAndPrompt(4);
      expect(_reviewRequested, false);

      await ReviewService.instance.checkAndPrompt(6);
      expect(_reviewRequested, false);
    });

    test('triggers review at exactly 5 entries', () async {
      await ReviewService.instance.checkAndPrompt(5);
      expect(_reviewRequested, true);
    });

    test('review prompt only fires once (never repeats)', () async {
      // First call at count 5 should trigger
      await ReviewService.instance.checkAndPrompt(5);
      expect(_reviewRequested, true);

      // Reset tracker
      _reviewRequested = false;

      // Second call at count 5 should NOT trigger (pref already set)
      await ReviewService.instance.checkAndPrompt(5);
      expect(_reviewRequested, false);
    });

    test('does not trigger when already shown (pref pre-set)', () async {
      SharedPreferences.setMockInitialValues({'review_prompt_shown': true});

      await ReviewService.instance.checkAndPrompt(5);
      expect(_reviewRequested, false);
    });

    test('does not request review when in_app_review is unavailable', () async {
      _mockInAppReview(available: false);

      await ReviewService.instance.checkAndPrompt(5);
      expect(_reviewRequested, false);

      // But it should still mark as shown so it won't retry
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('review_prompt_shown'), true);
    });
  });
}
