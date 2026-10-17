import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshie_store_environment/oshie_store_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('jp.tipies.oshie/store-environment');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() { debugDefaultTargetPlatformOverride = TargetPlatform.iOS; });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });
  for (final value in ['production', 'sandbox', 'unknown', 'unsupported']) {
    test('interactive fixed result $value', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'refreshFromUserAction'); expect(call.arguments, isNull);
        return value;
      });
      expect(await OshieStoreEnvironmentReader.refreshFromUserAction(), switch(value) {
        'production' => OshieStoreEnvironment.production,
        'sandbox' => OshieStoreEnvironment.sandbox,
        _ => OshieStoreEnvironment.unknown,
      });
    });
  }
  test('interactive error and cancellation map to unknown and release fence', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      if (calls == 1) throw PlatformException(code: 'cancelled');
      return 'sandbox';
    });
    expect(await OshieStoreEnvironmentReader.refreshFromUserAction(), OshieStoreEnvironment.unknown);
    expect(calls, 1);
    expect(await OshieStoreEnvironmentReader.refreshFromUserAction(), OshieStoreEnvironment.sandbox);
    expect(calls, 2);
  });
  test('missing plugin stays unknown', () async {
    expect(await OshieStoreEnvironmentReader.refreshFromUserAction(), OshieStoreEnvironment.unknown);
  });
  test('double tap coalesces one channel request', () async {
    var calls = 0; final pending = Completer<String>();
    messenger.setMockMethodCallHandler(channel, (_) { calls++; return pending.future; });
    final first = OshieStoreEnvironmentReader.refreshFromUserAction();
    final second = OshieStoreEnvironmentReader.refreshFromUserAction();
    expect(identical(first, second), isTrue);
    pending.complete('sandbox');
    expect(await first, OshieStoreEnvironment.sandbox);
    expect(await second, OshieStoreEnvironment.sandbox);
    expect(calls, 1);
  });
  testWidgets('interactive waits beyond eight seconds without timeout or retry', (tester) async {
    var calls = 0; var done = false; final pending = Completer<String>();
    messenger.setMockMethodCallHandler(channel, (_) { calls++; return pending.future; });
    final result = OshieStoreEnvironmentReader.refreshFromUserAction().then((v) { done = true; return v; });
    await tester.pump(const Duration(minutes: 2));
    expect(done, isFalse); expect(calls, 1);
    pending.complete('sandbox'); await tester.pump();
    expect(await result, OshieStoreEnvironment.sandbox); expect(calls, 1);
    debugDefaultTargetPlatformOverride = null;
  });
  test('non-iOS paths never invoke channel', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async { calls++; return 'production'; });
    for (final platform in [TargetPlatform.android, TargetPlatform.macOS, TargetPlatform.linux, TargetPlatform.windows]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(await OshieStoreEnvironmentReader.current(), OshieStoreEnvironment.unknown);
      expect(await OshieStoreEnvironmentReader.refreshFromUserAction(), OshieStoreEnvironment.unknown);
    }
    expect(calls, 0);
  });
}
