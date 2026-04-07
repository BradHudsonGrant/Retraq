import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_storage.dart';

/// Shared brute-force lockout controller used by LockScreen and PinVerifySheet.
class LockoutController extends ChangeNotifier {
  LockoutController({
    FlutterSecureStorage? storage,
    DateTime Function()? now,
  }) : _secureStorage = storage ?? hardenedSecureStorage,
       _now = now ?? DateTime.now;

  final FlutterSecureStorage _secureStorage;
  final DateTime Function() _now;

  static const maxAttempts = 5;
  static const _maxLockoutSeconds = 300;

  static const _prefFailedAttempts = 'lock_failed_attempts';
  static const _prefLockoutCount = 'lock_lockout_count';
  static const _prefLockoutEnd = 'lock_lockout_end';
  static const _prefLockoutStart = 'lock_lockout_start';

  int _failedAttempts = 0;
  int _lockoutCount = 0;
  int _lockoutSecondsLeft = 0;
  bool _isLockedOut = false;
  Timer? _lockoutTimer;

  /// Tracks the most recent pending persistence write. Exposed (package-private
  /// via [pendingWrites]) so tests can await it without changing the public
  /// signature of [recordFailedAttempt].
  Future<void> _pendingWrite = Future.value();

  /// Future that completes when any in-flight persistence writes have finished.
  /// Intended for tests — production code does not need to await this.
  @visibleForTesting
  Future<void> get pendingWrites => _pendingWrite;

  int get failedAttempts => _failedAttempts;
  int get lockoutCount => _lockoutCount;
  int get lockoutSecondsLeft => _lockoutSecondsLeft;
  bool get isLockedOut => _isLockedOut;

  Future<void> loadState() async {
    _failedAttempts =
        int.tryParse(
          await _secureStorage.read(key: _prefFailedAttempts) ?? '',
        ) ??
        0;
    _lockoutCount =
        int.tryParse(await _secureStorage.read(key: _prefLockoutCount) ?? '') ??
        0;
    final lockoutEndMs =
        int.tryParse(await _secureStorage.read(key: _prefLockoutEnd) ?? '') ??
        0;
    final lockoutStartMs =
        int.tryParse(await _secureStorage.read(key: _prefLockoutStart) ?? '') ??
        0;
    if (lockoutEndMs > 0) {
      final lockoutEnd = DateTime.fromMillisecondsSinceEpoch(lockoutEndMs);
      // Fall back to (end - duration) for legacy state written by older
      // versions of this controller that did not persist the start timestamp.
      final lockoutStart = lockoutStartMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(lockoutStartMs)
          : lockoutEnd.subtract(_lockoutDuration);
      final now = _now();
      // Clock-rewind defense (Option A): if the current wall clock is BEFORE
      // the recorded lockout start, the user has moved the clock backwards.
      // Keep the full lockout active and do NOT release it early. Only release
      // once now >= lockoutEnd AND now >= lockoutStart.
      final clockRewound = now.isBefore(lockoutStart);
      final remainingSeconds = lockoutEnd.difference(now).inSeconds;
      if (clockRewound || remainingSeconds > 0) {
        // When the clock has been rewound we cannot trust wall-clock arithmetic
        // for the countdown, so fall back to the full original window.
        _lockoutSecondsLeft = clockRewound
            ? lockoutEnd.difference(lockoutStart).inSeconds
            : remainingSeconds;
        _isLockedOut = true;
        _startCountdown();
        notifyListeners();
      } else {
        await _clearPersisted();
      }
    }
  }

  /// Records a failed attempt and starts lockout if threshold reached.
  /// Returns true if lockout was triggered.
  ///
  /// Persistence happens asynchronously in the background; tests can await
  /// [pendingWrites] to flush pending writes before asserting on storage.
  bool recordFailedAttempt() {
    _failedAttempts++;
    // Persist on EVERY failure (not just the 5th) so that a force-stop
    // between attempts cannot reset the counter to zero. The write is
    // queued on [_pendingWrite] so tests can flush it deterministically.
    _pendingWrite = _persistFailedAttempts();
    if (_failedAttempts >= maxAttempts) {
      _pendingWrite = _startLockout();
      return true;
    }
    notifyListeners();
    return false;
  }

  Duration get _lockoutDuration {
    final seconds = (30 * (1 << _lockoutCount)).clamp(30, _maxLockoutSeconds);
    return Duration(seconds: seconds);
  }

  Future<void> _startLockout() async {
    final duration = _lockoutDuration;
    _lockoutCount++;
    _lockoutSecondsLeft = duration.inSeconds;
    _isLockedOut = true;
    final start = _now();
    final end = start.add(duration);
    await _persistLockout(start, end);
    _startCountdown();
    notifyListeners();
  }

  void _startCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _lockoutSecondsLeft--;
      if (_lockoutSecondsLeft <= 0) {
        timer.cancel();
        _pendingWrite = _clearPersisted();
        _isLockedOut = false;
        _failedAttempts = 0;
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  Future<void> clearLockout() async {
    _lockoutTimer?.cancel();
    await _clearPersisted();
    _failedAttempts = 0;
    _lockoutCount = 0;
    _isLockedOut = false;
    _lockoutSecondsLeft = 0;
    notifyListeners();
  }

  Future<void> _persistFailedAttempts() async {
    await _secureStorage.write(
      key: _prefFailedAttempts,
      value: '$_failedAttempts',
    );
  }

  Future<void> _persistLockout(
    DateTime lockoutStart,
    DateTime lockoutEnd,
  ) async {
    await _secureStorage.write(
      key: _prefFailedAttempts,
      value: '$_failedAttempts',
    );
    await _secureStorage.write(key: _prefLockoutCount, value: '$_lockoutCount');
    await _secureStorage.write(
      key: _prefLockoutStart,
      value: '${lockoutStart.millisecondsSinceEpoch}',
    );
    await _secureStorage.write(
      key: _prefLockoutEnd,
      value: '${lockoutEnd.millisecondsSinceEpoch}',
    );
  }

  Future<void> _clearPersisted() async {
    await _secureStorage.delete(key: _prefFailedAttempts);
    await _secureStorage.delete(key: _prefLockoutCount);
    await _secureStorage.delete(key: _prefLockoutStart);
    await _secureStorage.delete(key: _prefLockoutEnd);
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }
}
