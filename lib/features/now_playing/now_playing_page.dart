import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/app/theme/player_theme.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/lyrics/lyrics_lines.dart';
import 'package:nyaplayer/features/lyrics/lyrics_view.dart';
import 'package:nyaplayer/features/now_playing/playback_controls.dart';
import 'package:nyaplayer/features/now_playing/player_artwork.dart';
import 'package:nyaplayer/features/now_playing/player_menu.dart';
import 'package:nyaplayer/features/queue/queue_list.dart';
import 'package:nyaplayer/features/queue/queue_sheet.dart';
import 'package:nyaplayer/features/shared/faded_edges.dart';
import 'package:nyaplayer/features/shared/library_builder.dart';
import 'package:nyaplayer/features/shared/quality_badge.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// From this width, or in any landscape window, the player is the immersive
/// layout: cover on the left, lyrics (or queue) on the right, controls along
/// the bottom (UI-08).
const immersivePlayerWidth = 720.0;

bool useImmersivePlayer(Size size) =>
    size.width >= immersivePlayerWidth || size.width > size.height;

/// Full-window player. Phones get a compact layout; wide windows (and the
/// "expand" button of the desktop panel) get the immersive layout.
class NowPlayingPage extends ConsumerWidget {
  const NowPlayingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(queueProvider.select((s) => s.current));
    return PlayerThemeScope(
      seed: track?.coverSeed,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () => context.pop(),
        },
        child: Focus(
          autofocus: true,
          child: useImmersivePlayer(MediaQuery.sizeOf(context))
              ? _ImmersivePlayer(track: track)
              : _CompactPlayer(track: track),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phone layout

class _CompactPlayer extends StatefulWidget {
  const _CompactPlayer({required this.track});

  final Track? track;

  @override
  State<_CompactPlayer> createState() => _CompactPlayerState();
}

/// Debug-only (set by the preview hook): open the queue sheet when the phone
/// player first appears, for screenshots.
bool debugOpenQueueOnLaunch = false;

/// Phones go back with the system gesture, so only desktop windows narrow
/// enough for this layout get an explicit close button.
bool get _needsCloseButton => switch (defaultTargetPlatform) {
  TargetPlatform.android || TargetPlatform.iOS => false,
  _ => true,
};

class _CompactPlayerState extends State<_CompactPlayer>
    with SingleTickerProviderStateMixin {
  final _pages = PageController();
  int _page = 0;
  late final _queueAnimation = AnimationController(vsync: this)
    ..addStatusListener((_) => setState(() {}));
  late final _queue = QueueSheetDrag(_queueAnimation);

  @override
  void initState() {
    super.initState();
    if (debugOpenQueueOnLaunch) {
      debugOpenQueueOnLaunch = false;
      Future<void>.delayed(Durations.long4, () {
        if (mounted) _queue.open();
      });
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _queueAnimation.dispose();
    super.dispose();
  }

  void _goTo(int page) => _pages.animateToPage(
    page,
    duration: Durations.medium4,
    curve: Easing.emphasizedDecelerate,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final track = widget.track;
    return ColoredBox(
      color: scheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.45),
              scheme.surface,
            ],
            stops: const [0, 0.85],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: track == null
                ? Column(
                    children: [
                      if (_needsCloseButton)
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(0, 12, 12, 0),
                            child: _CloseButton(),
                          ),
                        ),
                      Expanded(
                        child: EmptyState(
                          icon: Icons.music_off_outlined,
                          title: l10n.notPlaying,
                          body: l10n.notPlayingHint,
                        ),
                      ),
                    ],
                  )
                : _withQueueSheet(
                    Column(
                      children: [
                        _TitleRow(
                          track: track,
                          items: [
                            PlayerMenuItem(
                              icon: Icons.lyrics_outlined,
                              label: l10n.lyrics,
                              selected: _page == 1,
                              onPressed: () => _goTo(_page == 1 ? 0 : 1),
                            ),
                            PlayerMenuItem(
                              icon: Icons.queue_music,
                              label: l10n.queue,
                              onPressed: _queue.open,
                            ),
                            PlayerMenuButton.equalizer(context),
                            PlayerMenuButton.songInfo(context, track),
                          ],
                        ),
                        Expanded(
                          child: PageView(
                            controller: _pages,
                            onPageChanged: (page) =>
                                setState(() => _page = page),
                            children: [
                              _CoverAndLyrics(
                                track: track,
                                onLyrics: () => _goTo(1),
                              ),
                              const FadedEdges(child: LyricsView()),
                            ],
                          ),
                        ),
                        _PageDots(count: 2, index: _page, onSelect: _goTo),
                        SeekBar(duration: track.duration),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: TransportControls(tonalSkip: false),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

extension on _CompactPlayerState {
  /// Puts the swipe-up queue sheet over [player]. A vertical drag anywhere on
  /// the player (outside scrolling lyrics) pulls the sheet up; the system back
  /// gesture closes it first.
  Widget _withQueueSheet(Widget player) {
    final scheme = Theme.of(context).colorScheme;
    final open = _queueAnimation.status != AnimationStatus.dismissed;
    return PopScope(
      canPop: !open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _queue.close();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          _queue.travel = constraints.maxHeight;
          return Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (d) => _queue.update(d.delta.dy),
                onVerticalDragEnd: (d) => _queue.end(d.primaryVelocity ?? 0),
                child: player,
              ),
              if (open) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _queue.close,
                    child: FadeTransition(
                      opacity: _queueAnimation,
                      child: ColoredBox(
                        color: scheme.scrim.withValues(alpha: 0.32),
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _queueAnimation,
                  builder: (context, child) => Positioned(
                    left: 0,
                    right: 0,
                    top: (1 - _queueAnimation.value) * constraints.maxHeight,
                    height: constraints.maxHeight,
                    child: child!,
                  ),
                  child: QueueSheet(drag: _queue),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context).collapsePlayer,
      icon: const Icon(Icons.close_fullscreen),
      onPressed: () => context.pop(),
    );
  }
}

/// Title and artist on the left; favourite and menu buttons on the same row,
/// centred on the title line.
class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.track, required this.items});

  final Track track;
  final List<PlayerMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          FavoriteButton(track: track),
          if (_needsCloseButton) const _CloseButton(),
          PlayerMenuButton(items: items),
        ],
      ),
    );
  }
}

/// Two-dot indicator under the swipeable cover / lyrics pages.
class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.index,
    required this.onSelect,
  });

  final int count;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            GestureDetector(
              onTap: () => onSelect(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                child: AnimatedContainer(
                  duration: Durations.medium2,
                  curve: Easing.emphasizedDecelerate,
                  width: i == index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == index ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Large cover, the audio-format pill right below it, then the three-line
/// lyrics at the lower left.
class _CoverAndLyrics extends StatelessWidget {
  const _CoverAndLyrics({required this.track, required this.onLyrics});

  final Track track;
  final VoidCallback onLyrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const pillBlock = 12.0 + 28;
        const gap = 12.0;
        final room =
            constraints.maxHeight - LyricsLines.height - pillBlock - gap;
        final size = (constraints.maxWidth * 0.88).clamp(
          0.0,
          room.clamp(0.0, 460.0),
        );
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: size,
              child: PlayerArtwork(track: track, maxSize: size),
            ),
            const SizedBox(height: 12),
            QualityBadge(track: track, tonal: true),
            const SizedBox(height: gap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: LyricsLines(track: track, onTap: onLyrics),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Wide / expanded layout

enum _Pane { lyrics, queue }

class _ImmersivePlayer extends StatefulWidget {
  const _ImmersivePlayer({required this.track});

  final Track? track;

  @override
  State<_ImmersivePlayer> createState() => _ImmersivePlayerState();
}

class _ImmersivePlayerState extends State<_ImmersivePlayer> {
  _Pane _pane = _Pane.lyrics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final track = widget.track;
    // Landscape phones: less chrome around the cover.
    final short = MediaQuery.sizeOf(context).height < 500;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.55),
              scheme.surface,
              scheme.tertiaryContainer.withValues(alpha: 0.35),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              if (track == null)
                EmptyState(
                  icon: Icons.music_off_outlined,
                  title: l10n.notPlaying,
                  body: l10n.notPlayingHint,
                )
              else
                Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          48,
                          short ? 56 : 64,
                          48,
                          8,
                        ),
                        child: _Stage(track: track, pane: _pane, short: short),
                      ),
                    ),
                    _BottomControls(track: track, short: short),
                  ],
                ),
              Positioned(
                top: 12,
                right: 16,
                child: Row(
                  children: [
                    if (track != null) ...[
                      LyricsQueueToggle(
                        selected: switch (_pane) {
                          _Pane.lyrics => PlayerView.lyrics,
                          _Pane.queue => PlayerView.queue,
                        },
                        onChanged: (view) => setState(
                          () => _pane = view == PlayerView.queue
                              ? _Pane.queue
                              : _Pane.lyrics,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    IconButton(
                      tooltip: l10n.collapsePlayer,
                      icon: const Icon(Icons.close_fullscreen),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cover + title block on the left, lyrics (or queue) on the right. The right
/// pane is exactly as tall as the cover and aligned with its top and bottom.
class _Stage extends StatelessWidget {
  const _Stage({required this.track, required this.pane, required this.short});

  final Track track;
  final _Pane pane;

  /// Short windows (landscape phones): smaller caption (no quality badge) and
  /// a smaller minimum cover.
  final bool short;

  static const _gap = 48.0;

  @override
  Widget build(BuildContext context) {
    final titleGap = short ? 8.0 : 24.0;
    final titleHeight = short ? 62.0 : 112.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = (constraints.maxWidth - _gap) / 2;
        final size = math.max(
          short ? 64.0 : 160.0,
          math.min(
            math.min(columnWidth, 520.0),
            constraints.maxHeight - titleGap - titleHeight,
          ),
        );
        return Center(
          child: SizedBox(
            height: size + titleGap + titleHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SizedBox.square(
                        dimension: size,
                        child: PlayerArtwork(track: track, maxSize: size),
                      ),
                      SizedBox(height: titleGap),
                      SizedBox(
                        height: titleHeight,
                        child: _CoverCaption(track: track, compact: short),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  child: SizedBox(
                    height: size,
                    child: FadedEdges(
                      child: AnimatedSwitcher(
                        duration: Durations.medium2,
                        child: switch (pane) {
                          _Pane.lyrics => const LyricsView(
                            key: ValueKey('lyrics'),
                          ),
                          _Pane.queue => const QueueList(
                            key: ValueKey('queue'),
                            padding: FadedEdges.fadePadding,
                          ),
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CoverCaption extends StatelessWidget {
  const _CoverCaption({required this.track, this.compact = false});

  final Track track;

  /// Title and artist only.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          track.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          track.artist,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (!compact) ...[
          const SizedBox(height: 6),
          QualityBadge(track: track),
        ],
      ],
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({required this.track, this.short = false});

  final Track track;
  final bool short;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, short ? 0 : 8, 24, short ? 8 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerControlsRow(
                track: track,
                transport: const TransportControls(large: false, spacing: 16),
                menuItems: [
                  PlayerMenuButton.equalizer(context),
                  PlayerMenuButton.songInfo(context, track),
                ],
              ),
              const SizedBox(height: 4),
              SeekBar(duration: track.duration, inline: true),
            ],
          ),
        ),
      ),
    );
  }
}
