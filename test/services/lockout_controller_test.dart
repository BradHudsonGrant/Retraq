import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/lockout_controller.dart';

/// In-memory backing store for the mocked secure storage channel.
/// Shared across the test so a fresh [LockoutController] can "reload" state.
late Map<String, String> _mockStore;

/// Installs a mock handler for the flutter_secure_storage method channel
/// backed by [_mockStore]. Simulates a force-stop: writes are flushed, then
/// a new LockoutController reads from the same underlying store.
void _installMockSecureStorage() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
        switch (call.method) {
          case 'read':
            return _mockStore[args['key'] as String];
          case 'readAll':
            return Map<String, String>.from(_mockStore);
          case 'write':
            _mockStore[args['key'] as String] = args['value'] as String;
            return null;
          case 'delete':
            _mockStore.remove(args['key'] as String);
            return null;
          case 'deleteAll':
            _mockStore.clear();
            return null;
          case 'containsKey':
            return _mockStore.containsKey(args['key'] as String);
          default:
            return null;
        }
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _mockStore = <String, String>{};
    _installMockSecureStorage();
  });

  tearDown(() {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  LockoutController makeController({DateTime Function()? now}) {
    return LockoutController(storage: const FlutterSecureStorage(), now: now);
  }

  test('1 failure persists across reload', () async {
    final c1 = makeController();
    c1.recordFailedAttempt();
    await c1.pendingWrites;
    expect(c1.failedAttempts, 1);
    c1.dispose();

    // Simulate force-stop + relaunch: brand new controller, same store.
    final c2 = makeController();
    await c2.loadState();
    expect(
      c2.failedAttempts,
      1,
      reason: 'Attempt 1 must be persisted, not held only in memory.',
    );
    c2.dispose();
  });

  test('4 failures survive force-stop', () async {
    final c1 = makeController();
    c1.recordFailedAttempt();
    await c1.pendingWrites;
    c1.recordFailedAttempt();
    await c1.pendingWrites;
    c1.recordFailedAttempt();
    await c1.pendingWrites;
    c1.recordFailedAttempt();
    await c1.pendingWrites;
    expect(c1.failedAttempts, 4);
    expect(c1.isLockedOut, false);
    c1.dispose();

    // Force-stop: new controller reads from the same mock store.
    final c2 = makeController();
    await c2.loadState();
    expect(
      c2.failedAttempts,
      4,
      reason:
          'All 4 attempts must be persisted so force-stop cannot reset the counter.',
    );
    expect(c2.isLockedOut, false);
    c2.dispose();
  });

  test('5th failure triggers lockout', () async {
    final c = makeController();
    bool triggered = false;
    for (var i = 0; i < 5; i++) {
      triggered = c.recordFailedAttempt();
      await c.pendingWrites;
    }
    expect(triggered, true);
    expect(c.isLockedOut, true);
    expect(c.failedAttempts, 5);
    c.dispose();
  });

  test('successful PIN clears the count', () async {
    final c = makeController();
    c.recordFailedAttempt();
    await c.pendingWrites;
    c.recordFailedAttempt();
    await c.pendingWrites;
    c.recordFailedAttempt();
    await c.pendingWrites;
    expect(c.failedAttempts, 3);

    await c.clearLockout();
    expect(c.failedAttempts, 0);
    expect(c.isLockedOut, false);

    // And the store should be wiped so a new controller sees zero.
    final c2 = makeController();
    await c2.loadState();
    expect(c2.failedAttempts, 0);
    c2.dispose();
    c.dispose();
  });

  test(
    'clock rewind during lockout does NOT release lockout prematurely',
    () async {
      // Fixed "real" time at which the lockout is triggered.
      final lockoutTime = DateTime(2026, 4, 6, 12, 0, 0);
      var fakeNow = lockoutTime;

      // Build a controller that reports [fakeNow] as the current time.
      final c1 = LockoutController(
        storage: const FlutterSecureStorage(),
        now: () => fakeNow,
      );

      // Hit the 5-failure threshold to start a lockout.
      for (var i = 0; i < 5; i++) {
        c1.recordFailedAttempt();
        await c1.pendingWrites;
      }
      expect(c1.isLockedOut, true);
      c1.dispose();

      // Simulate an attacker rewinding the system clock by 1 hour — far further
      // than the (max 5-minute) lockout window would normally take to expire.
      fakeNow = lockoutTime.subtract(const Duration(hours: 1));

      // Load state on a fresh controller with the rewound clock.
      final c2 = LockoutController(
        storage: const FlutterSecureStorage(),
        now: () => fakeNow,
      );
      await c2.loadState();

      // The lockout MUST still be active — wall-clock rewind must not release it.
      expect(
        c2.isLockedOut,
        true,
        reason:
            'Rewinding the clock before the lockout start must not release the lockout.',
      );
      c2.dispose();
    },
  );
}
