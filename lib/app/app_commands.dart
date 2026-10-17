import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/app/router.dart';
import 'package:nyaplayer/app/window_chrome.dart';
import 'package:nyaplayer/features/search/library_search_delegate.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

class _SettingsIntent extends Intent {
  const _SettingsIntent();
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

enum _PlaybackCommand { toggle, previous, next }

class _PlaybackIntent extends Intent {
  const _PlaybackIntent(this.command);
  final _PlaybackCommand command;
}

/// Disabled actions let text editing shortcuts keep their normal behavior.
class _PlaybackAction extends Action<_PlaybackIntent> {
  _PlaybackAction(this.onInvoke);
  final void Function(_PlaybackCommand) onInvoke;

  @override
  bool isEnabled(_PlaybackIntent intent) {
    final context = FocusManager.instance.primaryFocus?.context;
    return context?.widget is! EditableText &&
        context?.findAncestorStateOfType<EditableTextState>() == null;
  }

  @override
  Object? invoke(_PlaybackIntent intent) {
    onInvoke(intent.command);
    return null;
  }
}

/// macOS application commands share one entry point with the native app menu.
class AppCommands extends ConsumerStatefulWidget {
  const AppCommands({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppCommands> createState() => _AppCommandsState();
}

class _AppCommandsState extends ConsumerState<AppCommands> {
  static const _channel = MethodChannel('nyaplayer/commands');
  late final bool _macOS;
  bool _searchOpen = false;
  bool _settingsOpen = false;
  ProviderSubscription<QueueState>? _statusListener;
  ({bool playing, bool hasTrack, String title, String show, String quit})?
  _statusControl;

  @override
  void initState() {
    super.initState();
    _macOS = isMacOS;
    if (_macOS) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'openSettings') _openSettings();
        if (call.method == 'togglePlayback') _playback(_PlaybackCommand.toggle);
        if (call.method == 'previousTrack') {
          _playback(_PlaybackCommand.previous);
        }
        if (call.method == 'nextTrack') _playback(_PlaybackCommand.next);
      });
      // A hidden window may not render frames. Keep the native status menu
      // current directly from state changes instead of waiting for a paint.
      _statusListener = ref.listenManual(
        queueProvider,
        (_, _) => _syncStatusMenu(),
      );
    }
  }

  @override
  void dispose() {
    if (_macOS) _channel.setMethodCallHandler(null);
    _statusListener?.close();
    super.dispose();
  }

  void _syncStatusMenu() {
    if (!mounted || !_macOS) return;
    final state = ref.read(queueProvider);
    final l10n = AppLocalizations.of(context);
    final value = (
      playing: state.playing,
      hasTrack: state.current != null,
      title: state.current?.title ?? l10n.notPlaying,
      show: l10n.showAppWindow,
      quit: l10n.quitApp,
    );
    if (_statusControl == value) return;
    _statusControl = value;
    unawaited(
      _channel
          .invokeMethod<void>('statusMenu', {
            'title': value.title,
            'hasTrack': value.hasTrack,
            'show': value.show,
            'playPause': value.playing ? l10n.pause : l10n.play,
            'previous': l10n.previous,
            'next': l10n.next,
            'quit': value.quit,
          })
          .catchError((Object _) {}),
    );
  }

  void _openSettings() {
    if (_settingsOpen) return;
    final router = ref.read(routerProvider);
    final path = router.routerDelegate.currentConfiguration.last.route.path;
    if (path == '/settings' || path == '/preferences') return;
    _settingsOpen = true;
    unawaited(
      router.push<void>('/preferences').whenComplete(() {
        _settingsOpen = false;
      }),
    );
  }

  Future<void> _openSearch() async {
    if (_searchOpen) return;
    final context = ref.read(rootNavigatorKeyProvider).currentContext;
    if (context == null) return;
    _searchOpen = true;
    try {
      await showSearch<void>(
        context: context,
        useRootNavigator: true,
        delegate: LibrarySearchDelegate(
          hint: AppLocalizations.of(context).searchHint,
        ),
      );
    } finally {
      _searchOpen = false;
    }
  }

  void _playback(_PlaybackCommand command) {
    final queue = ref.read(queueProvider.notifier);
    unawaited(switch (command) {
      _PlaybackCommand.toggle => queue.togglePlay(),
      _PlaybackCommand.previous => queue.skipPrevious(),
      _PlaybackCommand.next => queue.skipNext(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_macOS) return widget.child;
    ref.watch(queueProvider.select((state) => (state.playing, state.current)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncStatusMenu();
    });
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.comma, meta: true):
            _SettingsIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, meta: true): _SearchIntent(),
        SingleActivator(LogicalKeyboardKey.space): _PlaybackIntent(
          _PlaybackCommand.toggle,
        ),
        SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true):
            _PlaybackIntent(_PlaybackCommand.previous),
        SingleActivator(LogicalKeyboardKey.arrowRight, meta: true):
            _PlaybackIntent(_PlaybackCommand.next),
      },
      child: Actions(
        actions: {
          _SettingsIntent: CallbackAction<_SettingsIntent>(
            onInvoke: (_) {
              _openSettings();
              return null;
            },
          ),
          _SearchIntent: CallbackAction<_SearchIntent>(
            onInvoke: (_) {
              unawaited(_openSearch());
              return null;
            },
          ),
          _PlaybackIntent: _PlaybackAction(_playback),
        },
        child: Focus(autofocus: true, child: widget.child),
      ),
    );
  }
}
