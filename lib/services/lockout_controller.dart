import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shared brute-force lockout controller used by LockScreen and PinVerifySheet.
class LockoutController extends ChangeNotifier {
  LockoutController({FlutterSecureStorage? storage})
    : _secureStorage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const maxAttempts = 5;
  static const _maxLockoutSeconds = 300;

  static const _prefFailedAttempts = 'lock_failed_attempts';
  static const _prefLockoutCount = 'lock_lockout_count';
  static const _prefLockoutEnd = 'lock_lockout_end';

  int _failedAttempts = 0;
  int _lockoutCount = 0;
  int _lockoutSecondsLeft = 0;
  bool _isLockedOut = false;
  Timer? _lockoutTimer;

  int get failedAttempts => _failedAttempts;
  int get lockoutCount => _lockoutCount;
  int get lockoutSecondsLeft => _lockoutSecondsLeft;
  bool get isLockedOut => _isLockedOut;

  String statusText({String wrongPinPrefix = 'Wrong PIN'}) {
    if (_isLockedOut) return 'Too many attempts. Wait ${_lockoutSecondsLeft}s.';
    if (_failedAttempts > 0) {
      final remaining = maxAttempts - _failedAttempts;
      return '$wrongPinPrefix. $remaining ${remaining == 1 ? 'attempt' : 'attempts'} remaining.';
    }
    return 'Enter your PIN';
  }

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
    if (lockoutEndMs > 0) {
      final lockoutEnd = DateTime.fromMillisecondsSinceEpoch(lockoutEndMs);
      final remaining = lockoutEnd.difference(DateTime.now()).inSeconds;
      if (remaining > 0) {
        _lockoutSecondsLeft = remaining;
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
  bool recordFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      _startLockout();
      return true;
    }
    notifyListeners();
    return false;
  }

  Duration get _lockoutDuration {
    final seconds = (30 * (1 << _lockoutCount)).clamp(30, _maxLockoutSeconds);
    return Duration(seconds: seconds);
  }

  void _startLockout() {
    final duration = _lockoutDuration;
    _lockoutCount++;
    _lockoutSecondsLeft = duration.inSeconds;
    _isLockedOut = true;
    final lockoutEnd = DateTime.now().add(duration);
    _persistLockout(lockoutEnd);
    _startCountdown();
    notifyListeners();
  }

  void _startCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _lockoutSecondsLeft--;
      if (_lockoutSecondsLeft <= 0) {
        timer.cancel();
        _clearPersisted();
        _isLockedOut = false;
        _failedAttempts = 0;
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  Future<void> clearLockout() async {
    await _clearPersisted();
    _failedAttempts = 0;
    _lockoutCount = 0;
    notifyListeners();
  }

  Future<void> _persistLockout(DateTime lockoutEnd) async {
    await _secureStorage.write(
      key: _prefFailedAttempts,
      value: '$_failedAttempts',
    );
    await _secureStorage.write(key: _prefLockoutCount, value: '$_lockoutCount');
    await _secureStorage.write(
      key: _prefLockoutEnd,
      value: '${lockoutEnd.millisecondsSinceEpoch}',
    );
  }

  Future<void> _clearPersisted() async {
    await _secureStorage.delete(key: _prefFailedAttempts);
    await _secureStorage.delete(key: _prefLockoutCount);
    await _secureStorage.delete(key: _prefLockoutEnd);
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }
}
