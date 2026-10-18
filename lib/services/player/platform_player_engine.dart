import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nyaplayer/services/eq/eq_state.dart';
import 'package:nyaplayer/services/player/player_engine.dart';

/// [PlayerEngine] backed by the platform's own audio stack (TECH_SPEC §4.7):
/// Media3 ExoPlayer on Android (`AndroidPlayerEngine.kt`, M10-2) and
/// AVAudioEngine on macOS (`MacPlayerEngine.swift`, M10-6). Both native sides
/// speak the same channel protocol, so this class only translates calls and
/// events. Position is polled while playing, as in `RustPlayerEngine`.
///
/// The equalizer is wired on macOS; on Android [setEqualizer] is accepted and
/// ignored natively until M10-4.
class PlatformPlayerEngine implements PlayerEngine {
  PlatformPlayerEngine({
    this.positionInterval = const Duration(milliseconds: 200),
  }) {
    _method.setMethodCallHandler(_onNativeCall);
    _subscribe();
  }

  static const _method = MethodChannel('nyaplayer/player');
  static const _eventChannel = EventChannel('nyaplayer/player/events');

  final Duration positionInterval;

  late StreamSubscription<dynamic> _events;
  final _playing = StreamController<bool>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _index = StreamController<int?>.broadcast();
  final _completed = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();
  Timer? _ticker;
  bool _disposed = false;

  @override
  Stream<bool> get playing => _playing.stream;
  @override
  Stream<Duration> get position => _position.stream;
  @override
  Stream<int?> get currentIndex => _index.stream;
  @override
  Stream<bool> get completed => _completed.stream;
  @override
  Stream<String> get errors => _errors.stream;

  void _subscribe() {
    _events = _eventChannel.receiveBroadcastStream().listen(_onEvent);
  }

  /// The native player survives activity recreation (background playback),
  /// but a new activity attaches a new channel instance. Re-subscribe so the
  /// native side replays its current state to this engine.
  Future<void> _onNativeCall(MethodCall call) async {
    if (call.method != 'resubscribe' || _disposed) return;
    await _events.cancel();
    _subscribe();
  }

  void _onEvent(dynamic raw) {
    if (_disposed || raw is! Map) return;
    switch (raw['kind']) {
      case 'playing':
        final playing = raw['playing'] as bool;
        _playing.add(playing);
        _setTicking(playing);
      case 'currentIndex':
        _index.add(raw['index'] as int?);
        unawaited(_emitPosition());
      case 'completed':
        _completed.add(true);
        unawaited(_emitPosition());
      case 'error':
        _errors.add(raw['message'] as String? ?? 'playback error');
    }
  }

  void _setTicking(bool on) {
    _ticker?.cancel();
    _ticker = on
        ? Timer.periodic(positionInterval, (_) => _emitPosition())
        : null;
    unawaited(_emitPosition());
  }

  Future<void> _emitPosition() async {
    if (_disposed) return;
    final ms = await _method.invokeMethod<int>('position') ?? 0;
    if (!_disposed) _position.add(Duration(milliseconds: ms));
  }

  @override
  Future<void> openQueue(
    List<String> filePaths, {
    int startIndex = 0,
    bool autoplay = true,
  }) => _method.invokeMethod<void>('openQueue', {
    'paths': filePaths,
    'startIndex': startIndex < 0 ? 0 : startIndex,
    'autoplay': autoplay,
  });

  @override
  Future<void> play() => _method.invokeMethod<void>('play');

  @override
  Future<void> pause() => _method.invokeMethod<void>('pause');

  @override
  Future<void> seek(Duration position) async {
    final ms = position.isNegative ? 0 : position.inMilliseconds;
    await _method.invokeMethod<void>('seek', {'positionMs': ms});
    // Reflect the target at once so the slider does not jump back.
    if (!_disposed) _position.add(Duration(milliseconds: ms));
  }

  @override
  Future<void> jumpTo(int index) async {
    if (index >= 0) {
      await _method.invokeMethod<void>('jumpTo', {'index': index});
    }
  }

  @override
  Future<void> add(String filePath) =>
      _method.invokeMethod<void>('add', {'path': filePath});

  @override
  Future<void> insert(int index, String filePath) => _method.invokeMethod<void>(
    'insert',
    {'index': index < 0 ? 0 : index, 'path': filePath},
  );

  @override
  Future<void> remove(int index) async {
    if (index >= 0) {
      await _method.invokeMethod<void>('remove', {'index': index});
    }
  }

  @override
  Future<void> move(int from, int to) async {
    if (from >= 0 && to >= 0) {
      await _method.invokeMethod<void>('move', {'from': from, 'to': to});
    }
  }

  @override
  Future<void> reorder(List<int> order) =>
      _method.invokeMethod<void>('reorder', {'order': order});

  @override
  Future<void> setLoopMode(LoopMode mode) =>
      _method.invokeMethod<void>('setLoopMode', {'mode': mode.name});

  @override
  Future<void> setEqualizer(EqParams params) =>
      _method.invokeMethod<void>('setEqualizer', {
        'enabled': params.enabled,
        'gainsDb': params.gains,
        'preampDb': params.preamp,
      });

  @override
  Future<void> setVolume(double volume) => _method.invokeMethod<void>(
    'setVolume',
    {'volume': volume.clamp(0.0, 1.0)},
  );

  @override
  Future<void> dispose() async {
    _disposed = true;
    _ticker?.cancel();
    await _events.cancel();
    await _method.invokeMethod<void>('pause');
    await Future.wait([
      _playing.close(),
      _position.close(),
      _index.close(),
      _completed.close(),
      _errors.close(),
    ]);
  }
}
