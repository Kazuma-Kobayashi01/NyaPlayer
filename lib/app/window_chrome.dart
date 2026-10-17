import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Height of the strip the macOS traffic lights occupy at the top-left of the
/// window now that the system title bar is gone. Matches the traffic light
/// placement in `macos/Runner/MainFlutterWindow.swift`.
const macTitlebarInset = 34.0;

bool get isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

/// Whether the macOS window is in full screen (no traffic lights, no inset).
final windowFullScreenProvider =
    NotifierProvider<WindowFullScreenController, bool>(
      WindowFullScreenController.new,
    );

class WindowFullScreenController extends Notifier<bool> {
  static const _channel = MethodChannel('nyaplayer/window');

  @override
  bool build() {
    if (!isMacOS) return false;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'fullScreen') state = call.arguments as bool;
    });
    ref.onDispose(() => _channel.setMethodCallHandler(null));
    _channel.invokeMethod<bool>('isFullScreen').then((value) {
      if (ref.mounted) state = value ?? false;
    }, onError: (_) {});
    return false;
  }
}

/// Reserves the title-bar strip as a top safe-area inset on macOS so pages
/// (app bars, player headers) stay clear of the traffic lights.
class TitlebarInset extends ConsumerWidget {
  const TitlebarInset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isMacOS || ref.watch(windowFullScreenProvider)) return child;
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        padding: media.padding.copyWith(
          top: math.max(media.padding.top, macTitlebarInset),
        ),
        viewPadding: media.viewPadding.copyWith(
          top: math.max(media.viewPadding.top, macTitlebarInset),
        ),
      ),
      child: child,
    );
  }
}
