import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_log.dart';

/// Controls Android's `WindowManager.LayoutParams.FLAG_SECURE`, which blocks
/// screenshots, screen recording, and Recent Apps thumbnails while the app is
/// in the foreground.
///
/// FLAG_SECURE is applied unconditionally in Retraq, not gated on app lock.
/// Journal content is sensitive (entries describe day-to-day life, mood,
/// health-adjacent notes) and should not appear in Recents thumbnails or be
/// screenshot-able regardless of whether the user set up a PIN. Users who want
/// to screenshot their own app can export instead.
///
/// iOS has no direct equivalent; calls are no-ops there. The iOS equivalent is
/// the inactive-state blur overlay in `main.dart`.

@visibleForTesting
const flagSecureChannelName = 'com.retraq.app/flag_secure';

const _channel = MethodChannel(flagSecureChannelName);

/// Adds or clears `FLAG_SECURE` depending on [enabled]. Errors are swallowed
/// with a log so a platform-channel failure cannot crash the app.
Future<void> setFlagSecure(bool enabled) async {
  try {
    await _channel.invokeMethod(
      enabled ? 'addFlagSecure' : 'clearFlagSecure',
    );
  } catch (e) {
    AppLog.error('setFlagSecure', e);
  }
}
