import 'dart:async';

import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// Owns only window lifetime. Closing a window never stops its media session.
class DesktopLifecycle with WindowListener {
  DesktopLifecycle({required this.onExit});

  static const _channel = MethodChannel('nyaplayer/lifecycle');
  final Future<void> Function() onExit;
  Future<void>? _exit;

  Future<void> initialize() async {
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'prepareToExit') throw MissingPluginException();
      await prepareToExit();
    });
  }

  @override
  void onWindowClose() {
    if (_exit == null) unawaited(windowManager.hide());
  }

  Future<void> prepareToExit() => _exit ??= Future.sync(onExit);

  void dispose() {
    windowManager.removeListener(this);
    _channel.setMethodCallHandler(null);
  }
}
