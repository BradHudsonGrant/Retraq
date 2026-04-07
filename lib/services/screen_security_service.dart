import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Controls Android's `WindowManager.LayoutParams.FLAG_SECURE`, which blocks
/// screenshots, screen recording, and Recent Apps thumbnails while the app is
/// in the foreground. Enabled whenever app lock is on so the lock screen —
/// and anything that might leak after unlock — cannot be captured.
///
/// iOS has no direct equivalent; calls are no-ops there. The service owns the
/// platform channel so `main.dart` stays focused on app-level orchestration
/// and the behavior can be tested by swapping `MethodChannel.setMockMethodCallHandler`.
class ScreenSecurityService {
  ScreenSecurityService._();

  static final ScreenSecurityService instance = ScreenSecurityService._();

  @visibleForTesting
  static const channelName = 'com.retraq.app/flag_secure';

  static const _channel = MethodChannel(channelName);

  /// Adds or clears `FLAG_SECURE` depending on [enabled]. Errors are swallowed
  /// with a debug log so a platform-channel failure cannot crash the app.
  Future<void> setSecure(bool enabled) async {
    try {
      await _channel.invokeMethod(
        enabled ? 'addFlagSecure' : 'clearFlagSecure',
      );
    } catch (e) {
      debugPrint('FLAG_SECURE toggle failed: $e');
    }
  }
}
