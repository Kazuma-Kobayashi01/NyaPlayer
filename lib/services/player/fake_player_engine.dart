import 'dart:async';

import 'package:nyaplayer/services/eq/eq_state.dart';
import 'package:nyaplayer/services/player/player_engine.dart';

/// In-memory engine that simulates playback with a timer. It makes no sound.
/// Used for UI development and for QueueController tests.
class FakePlayerEngine implements PlayerEngine {
  FakePlayerEngine({
    required this.durationOf,
    this.tick = const Duration(milliseconds: 250),
  });

  final Duration Function(String path) durationOf;
  final Duration tick;

  final _playing = StreamController<bool>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _index = StreamController<int?>.broadcast();
  final _completed = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();

  final List<String> _paths = [];
  int? _current;
  bool _isPlaying = false;
  Duration _pos = Duration.zero;
  LoopMode _loop = LoopMode.none;
  Timer? _timer;
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

  List<String> get paths => List.unmodifiable(_paths);
  int? get index => _current;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _pos;
  LoopMode get loopMode => _loop;

  void _emitPosition() {
    if (!_disposed) _position.add(_pos);
  }

  void _setPlaying(bool value) {
    if (_isPlaying != value) {
      _isPlaying = value;
      if (!_disposed) _playing.add(value);
    }
    _timer?.cancel();
    _timer = null;
    if (value) {
      _timer = Timer.periodic(tick, (_) => _onTick());
    }
  }

  void _setIndex(int? value, {bool resetPosition = true}) {
    _current = value;
    if (resetPosition) _pos = Duration.zero;
    if (!_disposed) _index.add(value);
    _emitPosition();
  }

  Duration? get _currentDuration {
    final i = _current;
    if (i == null || i >= _paths.length) return null;
    return durationOf(_paths[i]);
  }

  void _onTick() {
    _pos += tick;
    final d = _currentDuration;
    if (d != null && _pos >= d) {
      _advance();
    } else {
      _emitPosition();
    }
  }

  void _advance() {
    final i = _current;
    if (i == null) return;
    if (_loop == LoopMode.one) {
      _pos = Duration.zero;
      _emitPosition();
    } else if (i + 1 < _paths.length) {
      _setIndex(i + 1);
    } else if (_loop == LoopMode.all) {
      _setIndex(0);
    } else {
      _pos = Duration.zero;
      _setPlaying(false);
      _emitPosition();
      if (!_disposed) _completed.add(true);
    }
  }

  @override
  Future<void> openQueue(
    List<String> filePaths, {
    int startIndex = 0,
    bool autoplay = true,
  }) async {
    _paths
      ..clear()
      ..addAll(filePaths);
    if (_paths.isEmpty) {
      _setIndex(null);
      _setPlaying(false);
      return;
    }
    _setIndex(startIndex.clamp(0, _paths.length - 1));
    _setPlaying(autoplay);
  }

  @override
  Future<void> play() async {
    if (_current != null) _setPlaying(true);
  }

  @override
  Future<void> pause() async => _setPlaying(false);

  @override
  Future<void> seek(Duration position) async {
    final d = _currentDuration;
    if (d == null) return;
    _pos = position < Duration.zero
        ? Duration.zero
        : (position > d ? d : position);
    _emitPosition();
  }

  @override
  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _paths.length) return;
    _setIndex(index);
  }

  @override
  Future<void> add(String filePath) async {
    _paths.add(filePath);
    if (_current == null) _setIndex(0);
  }

  @override
  Future<void> insert(int index, String filePath) async {
    final at = index.clamp(0, _paths.length);
    _paths.insert(at, filePath);
    final c = _current;
    if (c == null) {
      _setIndex(0);
    } else if (at <= c) {
      _current = c + 1;
      if (!_disposed) _index.add(_current);
    }
  }

  @override
  Future<void> remove(int index) async {
    if (index < 0 || index >= _paths.length) return;
    final c = _current;
    _paths.removeAt(index);
    if (_paths.isEmpty) {
      _setIndex(null);
      _setPlaying(false);
    } else if (c == null) {
      return;
    } else if (index < c) {
      _current = c - 1;
      if (!_disposed) _index.add(_current);
    } else if (index == c) {
      _setIndex(c >= _paths.length ? _paths.length - 1 : c);
    }
  }

  @override
  Future<void> move(int from, int to) async {
    if (from == to || from < 0 || from >= _paths.length) return;
    final c = _current;
    final item = _paths.removeAt(from);
    _paths.insert(to.clamp(0, _paths.length), item);
    if (c == null) return;
    var next = c;
    if (c == from) {
      next = to;
    } else if (from < c && to >= c) {
      next = c - 1;
    } else if (from > c && to <= c) {
      next = c + 1;
    }
    if (next != c) {
      _current = next;
      if (!_disposed) _index.add(_current);
    }
  }

  @override
  Future<void> setLoopMode(LoopMode mode) async => _loop = mode;

  EqParams eqParams = EqParams.flat;
  double volume = 1;

  @override
  Future<void> setEqualizer(EqParams params) async => eqParams = params;

  @override
  Future<void> setVolume(double value) async => volume = value;

  @override
  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    await Future.wait([
      _playing.close(),
      _position.close(),
      _index.close(),
      _completed.close(),
      _errors.close(),
    ]);
  }
}
