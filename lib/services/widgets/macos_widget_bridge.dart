import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/core/log.dart';
import 'package:nyaplayer/domain/cover_source.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/library/cover_cache.dart';
import 'package:nyaplayer/services/library/cover_providers.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// Publishes a small, durable view of the existing player to WidgetKit.
/// Every widget action uses QueueController; widgets never own an engine.
class MacOSWidgetBridge {
  MacOSWidgetBridge(
    this._container, {
    this._channel = const MethodChannel('nyaplayer/widget'),
    CoverCache? covers,
  }) : _covers = covers ?? _container.read(coverCacheProvider);

  final ProviderContainer _container;
  final MethodChannel _channel;
  final CoverCache _covers;
  final _subscriptions = <StreamSubscription<Object?>>[];
  ProviderSubscription<QueueState>? _queueSubscription;
  ProviderSubscription<Locale?>? _localeSubscription;
  late QueueController _controller;
  QueueState _state = const QueueState();
  Duration _position = Duration.zero;
  String _queueRevision = '';
  List<Map<String, Object>> _queue = const [];
  CoverSource? _coverSource;
  String? _artwork;
  int _artworkGeneration = 0;
  Future<void> _writes = Future.value();
  Future<void> _commands = Future.value();
  Timer? _publishTimer;
  DateTime _lastPositionWrite = DateTime.fromMillisecondsSinceEpoch(0);
  bool _started = false;
  bool _closed = false;

  Future<void> start() async {
    if (_started || _closed) return;
    // The extension needs macOS 14 for interactive desktop widgets. The main
    // player still supports macOS 12 and simply omits this integration there.
    if (await _channel.invokeMethod<bool>('isSupported') != true) return;
    _started = true;
    _controller = _container.read(queueProvider.notifier);
    _position = _controller.position;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'command') throw MissingPluginException();
      final command = Map<String, dynamic>.from(call.arguments as Map);
      final result = _commands.then((_) => _command(command));
      // Preserve per-click ordering without letting one stale widget action
      // poison all later controls. The original caller still gets its error.
      _commands = result.catchError((Object _) {});
      await result;
    });
    _queueSubscription = _container.listen(
      queueProvider,
      _onQueue,
      fireImmediately: true,
    );
    _localeSubscription = _container.listen(localeProvider, (_, _) {
      _schedulePublish();
    });
    _subscriptions.addAll([
      _container.read(playerEngineProvider).position.listen((position) {
        _position = position;
        // WidgetKit animates its timer progress itself. Keep the disk snapshot
        // fresh for newly added widgets without spending timeline reloads.
        final now = DateTime.now();
        if (now.difference(_lastPositionWrite) >= const Duration(seconds: 30)) {
          _lastPositionWrite = now;
          unawaited(_publish(reload: false));
        }
      }),
      _controller.seekEvents.listen((position) {
        _position = position;
        _schedulePublish();
      }),
    ]);
    await _publish();
    // Native App Intents can arrive during a cold start. Signal readiness only
    // after the previous playback queue has been restored by main().
    await _channel.invokeMethod<void>('ready');
  }

  void _onQueue(QueueState? previous, QueueState next) {
    if (_closed) return;
    _state = next;
    if (previous != null && previous.current != next.current) {
      _position = Duration.zero;
    }
    if (previous == null || !identical(previous.queue, next.queue)) {
      _queueRevision = sha1
          .convert(
            utf8.encode(
              jsonEncode([
                for (final track in next.queue) [track.id, track.path],
              ]),
            ),
          )
          .toString();
      _queue = [
        for (var index = 0; index < next.queue.length; index++)
          {
            'index': index,
            'id': next.queue[index].id,
            'title': next.queue[index].title,
            'artist': next.queue[index].artist,
            'durationMs': next.queue[index].duration.inMilliseconds,
          },
      ];
    }
    final source = next.current?.cover;
    if (_coverSource != source) {
      _coverSource = source;
      _artwork = source == null ? null : _covers.peek(source)?.thumbnail;
      final generation = ++_artworkGeneration;
      if (source != null) unawaited(_loadArtwork(source, generation));
    }
    _schedulePublish();
  }

  Future<void> _loadArtwork(CoverSource source, int generation) async {
    final cover = await _covers.load(source);
    if (_closed || generation != _artworkGeneration) return;
    _artwork = cover?.thumbnail;
    _schedulePublish();
  }

  void _schedulePublish() {
    if (_closed) return;
    _publishTimer?.cancel();
    _publishTimer = Timer(const Duration(milliseconds: 120), () {
      unawaited(_publish());
    });
  }

  Map<String, Object?> _snapshot({required bool running}) {
    final selected = _container.read(localeProvider);
    final locale = basicLocaleListResolution([
      selected ?? WidgetsBinding.instance.platformDispatcher.locale,
    ], AppLocalizations.supportedLocales);
    final strings = lookupAppLocalizations(locale);
    final track = _state.current;
    return {
      'schemaVersion': 1,
      'title': track?.title ?? '',
      'artist': track?.artist ?? '',
      'album': track?.album ?? '',
      'artworkSource': _artwork,
      'currentIndex': _state.currentIndex,
      'isPlaying': running && _state.playing,
      'appRunning': running,
      'positionMs': _position.inMilliseconds.clamp(
        0,
        track?.duration.inMilliseconds ?? 0,
      ),
      'durationMs': track?.duration.inMilliseconds ?? 0,
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      'shuffle': _state.shuffle,
      'repeatMode': _state.loopMode.name,
      'queueRevision': _queueRevision,
      'queue': _queue,
      'labels': {
        'notPlaying': strings.notPlaying,
        'emptyHint': strings.notPlayingHint,
        'queue': strings.queue,
        'queueEmpty': strings.queueEmpty,
        'play': strings.play,
        'pause': strings.pause,
        'previous': strings.previous,
        'next': strings.next,
        'repeatOff': strings.repeatOff,
        'repeatAll': strings.repeatAll,
        'repeatOne': strings.repeatOne,
        'shuffleOn': strings.shuffleOn,
        'shuffleOff': strings.shuffleOff,
      },
    };
  }

  Future<void> _publish({bool reload = true, bool running = true}) {
    if (!_started || (_closed && running)) return Future.value();
    final snapshot = _snapshot(running: running)..['reload'] = reload;
    _writes = _writes.then((_) async {
      try {
        await _channel.invokeMethod<void>('publishSnapshot', snapshot);
      } catch (error) {
        Log.w('WidgetKit', 'Cannot publish player snapshot: $error');
      }
    });
    return _writes;
  }

  Future<void> _command(Map<String, dynamic> command) async {
    if (_closed) throw PlatformException(code: 'player_closed');
    switch (command['action']) {
      case 'togglePlayback':
        await _controller.togglePlay();
      case 'previousTrack':
        await _controller.skipPrevious();
      case 'nextTrack':
        await _controller.skipNext();
      case 'toggleShuffle':
        await _controller.toggleShuffle();
      case 'cycleLoopMode':
        await _controller.cycleLoopMode();
      case 'playQueueItem':
        final index = command['index'];
        // A widget can still display an older queue after the player changes
        // context. Never play a different song at the same numeric position.
        if (command['queueRevision'] != _queueRevision ||
            index is! int ||
            index < 0 ||
            index >= _state.queue.length) {
          throw PlatformException(code: 'stale_queue');
        }
        await _controller.jumpTo(index);
        await _controller.play();
      default:
        throw PlatformException(code: 'unsupported_widget_command');
    }
    // Stream events from the engine are delivered before the next event turn.
    await Future<void>.delayed(Duration.zero);
    await _publish();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _publishTimer?.cancel();
    _queueSubscription?.close();
    _localeSubscription?.close();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    if (_started) await _publish(running: false);
    _channel.setMethodCallHandler(null);
  }
}
