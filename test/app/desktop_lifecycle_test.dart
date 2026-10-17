import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaplayer/app/desktop_lifecycle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native close hides the window without running shutdown; repeated quit cleans up once', () async {
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('window_manager'), (
      call,
    ) async {
      calls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        null,
      ),
    );
    var shutdowns = 0;
    final gate = Completer<void>();
    final lifecycle = DesktopLifecycle(
      onExit: () {
        shutdowns++;
        return gate.future;
      },
    );
    addTearDown(lifecycle.dispose);
    await lifecycle.initialize();
    expect(
      calls.map((call) => call.method),
      containsAllInOrder(['ensureInitialized', 'setPreventClose']),
    );
    expect(calls.last.arguments, {'isPreventClose': true});
    final closed = Completer<void>();
    ServicesBinding.instance.channelBuffers.push(
      'window_manager',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('onEvent', {'eventName': 'close'}),
      ),
      (_) => closed.complete(),
    );
    await closed.future;
    expect(calls.last.method, 'hide');
    expect(shutdowns, 0);
    final first = lifecycle.prepareToExit();
    final second = lifecycle.prepareToExit();
    await Future<void>.delayed(Duration.zero);
    expect(shutdowns, 1);
    final count = calls.length;
    lifecycle.onWindowClose();
    expect(calls.length, count);
    gate.complete();
    await Future.wait([first, second]);
  });
}
