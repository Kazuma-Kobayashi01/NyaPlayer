import 'dart:async';

import 'package:nyaplayer/services/eq/eq_state.dart';
import 'package:nyaplayer/services/player/player_engine.dart';
import 'package:nyaplayer/src/rust/api/player.dart' as rust;

/// [PlayerEngine] backed by the Rust core (TECH_SPEC §4.3). Commands are
/// synchronous FFI calls that only enqueue work on the engine thread; state
/// comes back on the Rust event stream. Position is not streamed by Rust: it
/// is polled every [positionInterval] while playing.
class RustPlayerEngine implements PlayerEngine {
  RustPlayerEngine({
    this.positionInterval = const Duration(milliseconds: 200),
  }) {
    _events = rust.playerEvents().listen(_onEvent);
  }

  final Duration positionInterval;

  late final StreamSubscription<rust.PlayerEvent> _events;
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

  Duration get currentPosition =>
      Duration(milliseconds: rust.playerPositionMs().toInt());

  void _onEvent(rust.PlayerEvent event) {
    if (_disposed) return;
    switch (event.kind) {
      case rust.PlayerEventKind.playing:
        _playing.add(event.playing);
        _setTicking(event.playing);
      case rust.PlayerEventKind.currentIndex:
        _index.add(event.index);
        _emitPosition();
      case rust.PlayerEventKind.completed:
        _completed.add(true);
        _emitPosition();
      case rust.PlayerEventKind.error:
        _errors.add(event.message ?? 'playback error');
    }
  }

  void _setTicking(bool on) {
    _ticker?.cancel();
    _ticker = on
        ? Timer.periodic(positionInterval, (_) => _emitPosition())
        : null;
    _emitPosition();
  }

  void _emitPosition() {
    if (!_disposed) _position.add(currentPosition);
  }

  @override
  Future<void> openQueue(
    List<String> filePaths, {
    int startIndex = 0,
    bool autoplay = true,
  }) async {
    rust.playerOpenQueue(
      paths: filePaths,
      startIndex: startIndex < 0 ? 0 : startIndex,
      autoplay: autoplay,
    );
  }

  @override
  Future<void> play() async => rust.playerPlay();

  @override
  Future<void> pause() async => rust.playerPause();

  @override
  Future<void> seek(Duration position) async {
    final ms = position.isNegative ? 0 : position.inMilliseconds;
    rust.playerSeek(positionMs: BigInt.from(ms));
    // The engine updates its position on its next poll; reflect the target
    // right away so the slider does not jump back.
    if (!_disposed) _position.add(Duration(milliseconds: ms));
  }

  @override
  Future<void> jumpTo(int index) async {
    if (index >= 0) rust.playerJumpTo(index: index);
  }

  @override
  Future<void> add(String filePath) async => rust.playerAdd(path: filePath);

  @override
  Future<void> insert(int index, String filePath) async =>
      rust.playerInsert(index: index < 0 ? 0 : index, path: filePath);

  @override
  Future<void> remove(int index) async {
    if (index >= 0) rust.playerRemove(index: index);
  }

  @override
  Future<void> move(int from, int to) async {
    if (from >= 0 && to >= 0) rust.playerMove(from: from, to: to);
  }

  @override
  Future<void> reorder(List<int> order) async =>
      rust.playerReorder(order: order);

  @override
  Future<void> setLoopMode(LoopMode mode) async => rust.playerSetRepeatMode(
    mode: switch (mode) {
      LoopMode.none => rust.RepeatMode.none,
      LoopMode.all => rust.RepeatMode.all,
      LoopMode.one => rust.RepeatMode.one,
    },
  );

  @override
  Future<void> setEqualizer(EqParams params) async => rust.playerSetEqualizer(
    enabled: params.enabled,
    gainsDb: params.gains,
    preampDb: params.preamp,
  );

  @override
  Future<void> setVolume(double volume) async =>
      rust.playerSetVolume(volume: volume.clamp(0.0, 1.0));

  @override
  Future<void> dispose() async {
    _disposed = true;
    _ticker?.cancel();
    await _events.cancel();
    rust.playerPause();
    await Future.wait([
      _playing.close(),
      _position.close(),
      _index.close(),
      _completed.close(),
      _errors.close(),
    ]);
  }
}
