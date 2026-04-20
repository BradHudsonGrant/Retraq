import 'package:shared_preferences/shared_preferences.dart';
import 'app_log.dart';

/// Keys identifying the local counters / stamps the app can bump.
///
/// The plan's Epic 11 tasks call out specific measurable surfaces
/// (e.g., `onThisDayOpened`, paywall-impression, recap-generated).
/// Adding a new key here is a one-line change — persistence is
/// owned by the active [AnalyticsBackend].
enum FeatureCounterKey {
  /// "on this day last year" card tap.
  onThisDayOpened,

  /// app opened from a notification tap (as opposed
  /// to cold-launch from the icon).
  notificationOpened,

  /// v1.1 paywall — when a free user lands on the Pro gate.
  proFeatureAttempted,

  /// v1.1 — user completed an AI-generated recap (Gemini Nano or
  /// cloud).
  recapGenerated,

  /// v1.1 — user tapped thumbs-up or thumbs-down on a recap.
  recapFeedbackGiven,
}

/// Facade for on-device analytics writes.
///
/// the single choke-point for every "bump a
/// counter" / "stamp a timestamp" call in the app. It honours the
/// `keep_usage_stats` SharedPreferences flag (default true) so a
/// user who toggles "Keep usage stats" off in Settings → Data
/// sees every write become a no-op.
///
/// Counters are **local only**. Network emission was already
/// impossible; the kill switch
/// controls whether we WRITE to the local store, not whether
/// we TRANSMIT.
///
/// Backend persistence (Drift tables for feature_counters,
/// app_sessions, recap_feedback, notification_events) ships in
/// separate commits. This first cut uses an in-memory map so the
/// facade exists, the kill switch is wired, and call sites can
/// land without waiting on the schema migration. Calling
/// `.bump(...)` today is a no-op in production apart from the
/// debug log; tests can inject a fake backend to observe writes.
///
/// ## Thread / isolate safety
/// The facade is a plain Dart class — single-isolate. Drift
/// writes will happen inside the backend's own transaction when
/// the persistent backend ships.
class AnalyticsService {
  AnalyticsService._({AnalyticsBackend? backend})
      : _backend = backend ?? _InMemoryAnalyticsBackend();

  static AnalyticsService instance = AnalyticsService._();

  /// Testing hook — swap in a fake backend or stub. Reset with
  /// `AnalyticsService.resetForTest()` when done.
  static void setBackendForTest(AnalyticsBackend backend) {
    instance = AnalyticsService._(backend: backend);
  }

  /// Resets the singleton to its production state (in-memory
  /// backend, default cached opt-in). Call from `tearDown` in
  /// tests that touched `setBackendForTest` to avoid bleed.
  static void resetForTest() {
    instance = AnalyticsService._();
  }

  /// SharedPreferences key controlling the kill switch. Default
  /// value when the key is absent is `true` — Agent 11's audit
  /// prefers opt-out over opt-in for local counters since nothing
  /// leaves the device by default regardless.
  static const _prefsKey = 'keep_usage_stats';

  final AnalyticsBackend _backend;

  /// Cached kill-switch state. Primed by [refreshFromPrefs] at
  /// app startup; refreshed synchronously by the Settings toggle
  /// calling [setEnabled] so the very next `bump` observes the
  /// change without an app restart.
  bool _enabled = true;
  bool get isEnabled => _enabled;

  /// Sync the cached flag from SharedPreferences. Call once during
  /// app boot (after `WidgetsFlutterBinding.ensureInitialized`).
  Future<void> refreshFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefsKey) ?? true;
    } catch (e, st) {
      // SharedPreferences unavailable on hostile envs / tests — be
      // permissive: default-on matches "nothing leaves the device
      // by default" regardless of local write state.
      AppLog.warn('AnalyticsService.refreshFromPrefs', e, st);
      _enabled = true;
    }
  }

  /// Write the kill switch to SharedPreferences and update the
  /// in-process cache. Settings toggle calls this on flip.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (e, st) {
      AppLog.warn('AnalyticsService.setEnabled', e, st);
    }
  }

  /// Bump a counter by 1. No-op when the kill switch is off or
  /// the backend is uninitialized.
  Future<void> bump(FeatureCounterKey key) async {
    if (!_enabled) return;
    await _backend.bump(key);
  }

  /// Read-back, primarily for tests and the opt-in anonymized
  /// export.
  int read(FeatureCounterKey key) => _backend.read(key);
}

/// Pluggable persistence layer. The default in-memory backend ships
/// today; a Drift-backed one replaces it when the v15 schema
/// migration lands.
abstract class AnalyticsBackend {
  Future<void> bump(FeatureCounterKey key);
  int read(FeatureCounterKey key);
}

/// Minimal in-memory backend — counts live until app process
/// exit. Useful for tests + a no-risk foundation while the Drift
/// tables land.
class _InMemoryAnalyticsBackend implements AnalyticsBackend {
  final Map<FeatureCounterKey, int> _counts = {};

  @override
  Future<void> bump(FeatureCounterKey key) async {
    _counts[key] = (_counts[key] ?? 0) + 1;
  }

  @override
  int read(FeatureCounterKey key) => _counts[key] ?? 0;
}

/// Recording test-fake — tests assert against the `.writes` list.
class RecordingAnalyticsBackend implements AnalyticsBackend {
  final List<FeatureCounterKey> writes = [];

  @override
  Future<void> bump(FeatureCounterKey key) async {
    writes.add(key);
  }

  @override
  int read(FeatureCounterKey key) =>
      writes.where((w) => w == key).length;
}
