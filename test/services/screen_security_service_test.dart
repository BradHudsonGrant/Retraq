import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/screen_security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(flagSecureChannelName);
  final invocations = <String>[];

  setUp(() {
    invocations.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          invocations.add(call.method);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('setFlagSecure(true) invokes addFlagSecure', () async {
    await setFlagSecure(true);
    expect(invocations, ['addFlagSecure']);
  });

  test('setFlagSecure(false) invokes clearFlagSecure', () async {
    await setFlagSecure(false);
    expect(invocations, ['clearFlagSecure']);
  });

  test('platform channel failure is swallowed, not rethrown', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'UNAVAILABLE');
        });

    // Should not throw.
    await setFlagSecure(true);
  });
}
