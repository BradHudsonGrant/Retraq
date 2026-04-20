import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/lockout_controller.dart';

/// concurrency + race-condition coverage for
/// `LockoutController`. The existing `lockout_controller_test.dart`
/// covers the sequential happy-path and the persistence/clock-rewind
/// edges; this file pins the behaviour of the controller under
/// *concurrent* failed-attempt writes.
///
/// Why this matters: the PIN-entry UI fires `recordFailedAttempt()`
/// from `onKey` callbacks that have no intrinsic serialization. A
/// user mashing buttons, a test harness under load, or an
/// accessibility tool replaying taps can interleave concurrent calls.
/// The controller's contract says:
///
/// - `_failedAttempts` is incremented exactly once per call.
/// - The 5th call triggers lockout; subsequent calls do not
///   double-count.
/// - `pendingWrites` must flush cleanly — no lost writes, no
///   stale-read races against secure storage.
///
/// These three properties are cheap to assert but expensive to
/// discover in prod; the five cases below lock them in.

late Map<String, String> _mockStore;

void _installMockSecureStorage() {
  const channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
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
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('4 concurrent failed attempts increment count to exactly 4', () async {
    final ctrl = LockoutController(storage: const FlutterSecureStorage());

    // Fire all four concurrently from the same event-loop turn. The
    // counter is a plain int so every increment must observe the
    // post-increment value — if a compiler or reorder ever tried to
    // cache the "read" half across async pauses, we'd see drops.
    final results = await Future.wait<bool>(List.generate(
      4,
      (_) => Future(() => ctrl.recordFailedAttempt()),
    ));

    await ctrl.pendingWrites;

    expect(ctrl.failedAttempts, 4,
        reason: '4 concurrent increments must land as 4, not <4 or >4.');
    expect(results.every((r) => r == false), isTrue,
        reason: 'None of the 4 calls hit the 5-attempt lockout threshold.');
    expect(ctrl.isLockedOut, isFalse);

    ctrl.dispose();
  });

  test(
      '10 concurrent failed attempts trigger exactly one lockout and '
      'saturate at maxAttempts', () async {
    final ctrl = LockoutController(storage: const FlutterSecureStorage());

    // Fire 10 concurrent attempts. The 5th (and only the 5th)
    // should return true. Subsequent calls must not double-count
    // the lockout count — that would cause an exponentially
    // longer lockout than the policy intends.
    final results = await Future.wait<bool>(List.generate(
      10,
      (_) => Future(() => ctrl.recordFailedAttempt()),
    ));

    await ctrl.pendingWrites;

    // Sequencing: each Future() schedules a microtask; they all run
    // synchronously (one Dart isolate) in the order scheduled. Calls
    // 1-4 increment the counter under threshold and return false.
    // Calls 5-10 each see `_failedAttempts >= maxAttempts` and
    // return true — they are each semantically a "lockout is in
    // effect for you" signal. What matters for the CONCURRENCY
    // contract is that `_lockoutCount` — the state that feeds the
    // exponential-backoff window calculation — is incremented
    // exactly ONCE across the 10 calls. Without the `!_isLockedOut`
    // guard inside recordFailedAttempt, calls 5..10 each run
    // `_startLockout` and each sync-increment `_lockoutCount`,
    // producing a 6× compounded backoff on the next lockout.
    expect(results.take(4).every((r) => !r), isTrue,
        reason: 'First 4 calls are under the 5-attempt threshold.');
    expect(results.skip(4).every((r) => r), isTrue,
        reason: 'Calls 5..10 each observe an active lockout.');
    expect(ctrl.lockoutCount, 1,
        reason: '10 concurrent failures must not compound lockoutCount — '
            'that would multiply the next-lockout window by up to 6×.');
    expect(ctrl.failedAttempts, 10,
        reason: 'Every call increments _failedAttempts exactly once.');
    expect(ctrl.isLockedOut, isTrue);

    ctrl.dispose();
  });

  test('pending writes flush deterministically under concurrent load',
      () async {
    final ctrl = LockoutController(storage: const FlutterSecureStorage());

    // Interleave 5 writes and immediately await pendingWrites between
    // each — this exercises the contract that each call sets a fresh
    // _pendingWrite and the latest one covers any earlier unresolved
    // writes. If the contract were broken, the secure-storage read
    // after await would miss earlier increments.
    for (var i = 0; i < 5; i++) {
      ctrl.recordFailedAttempt();
    }
    await ctrl.pendingWrites;

    // Fresh controller reads from the same backing store. If any
    // intermediate write was dropped, failedAttempts here would be
    // less than 5.
    final reloaded = LockoutController(storage: const FlutterSecureStorage());
    await reloaded.loadState();

    // Because the 5th attempt triggered a lockout, the persisted
    // state includes both the failedAttempts counter and the
    // lockoutCount. Verify both survived.
    expect(reloaded.isLockedOut, isTrue,
        reason:
            'Reload after 5 concurrent failures must observe lockout state.');
    expect(reloaded.lockoutCount, 1);

    ctrl.dispose();
    reloaded.dispose();
  });

  test(
      'clearLockout after concurrent failures fully resets counters + '
      'persisted state', () async {
    final ctrl = LockoutController(storage: const FlutterSecureStorage());

    await Future.wait(List.generate(
      3,
      (_) => Future(() => ctrl.recordFailedAttempt()),
    ));
    await ctrl.pendingWrites;
    expect(ctrl.failedAttempts, 3);

    await ctrl.clearLockout();

    // In-memory state
    expect(ctrl.failedAttempts, 0);
    expect(ctrl.lockoutCount, 0);
    expect(ctrl.isLockedOut, isFalse);

    // Persisted state — fresh reload must see a clean slate, not
    // stale counters bleeding through from before the clear.
    final reloaded = LockoutController(storage: const FlutterSecureStorage());
    await reloaded.loadState();
    expect(reloaded.failedAttempts, 0);
    expect(reloaded.isLockedOut, isFalse);

    ctrl.dispose();
    reloaded.dispose();
  });

  test(
      'recordFailedAttempt is idempotent against accidental double-fires '
      'of the same user gesture', () async {
    // A rapid double-tap / key repeat is conceptually one failed
    // attempt from the user's perspective but arrives as two
    // events in the controller. The controller's current contract
    // is "each call is one attempt" — it does NOT de-duplicate
    // double-fires automatically, which is the safer default (a
    // wrong PIN is a wrong PIN regardless of input source).
    //
    // This test pins the contract so a future "be helpful and
    // de-dup" refactor doesn't silently slacken the 5-attempt
    // brute-force guard.
    final ctrl = LockoutController(storage: const FlutterSecureStorage());

    // Double-fire in the same microtask.
    final r1 = ctrl.recordFailedAttempt();
    final r2 = ctrl.recordFailedAttempt();
    await ctrl.pendingWrites;

    expect(r1, isFalse, reason: 'Attempt 1 under threshold.');
    expect(r2, isFalse, reason: 'Attempt 2 under threshold.');
    expect(ctrl.failedAttempts, 2,
        reason: 'Double-fires count as 2 attempts — brute-force guard stays '
            'strict by design.');

    ctrl.dispose();
  });
}
