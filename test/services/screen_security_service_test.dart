import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/screen_security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(ScreenSecurityService.channelName);
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

  group('ScreenSecurityService', () {
    test('setSecure(true) invokes addFlagSecure', () async {
      await ScreenSecurityService.instance.setSecure(true);
      expect(invocations, ['addFlagSecure']);
    });

    test('setSecure(false) invokes clearFlagSecure', () async {
      await ScreenSecurityService.instance.setSecure(false);
      expect(invocations, ['clearFlagSecure']);
    });

    test('platform channel failure is swallowed, not rethrown', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(code: 'UNAVAILABLE');
          });

      // Should not throw.
      await ScreenSecurityService.instance.setSecure(true);
    });
  });
}
