import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nyaplayer/app/layout/adaptive_shell.dart';
import 'package:nyaplayer/features/lyrics/lyrics_lines.dart';
import 'package:nyaplayer/features/lyrics/lyrics_settings.dart';
import 'package:nyaplayer/features/lyrics/lyrics_view.dart';
import 'package:nyaplayer/features/now_playing/playback_controls.dart';
import 'package:nyaplayer/features/now_playing/player_artwork.dart';
import 'package:nyaplayer/features/now_playing/player_background.dart';
import 'package:nyaplayer/features/now_playing/player_menu.dart';
import 'package:nyaplayer/features/queue/queue_list.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/shared/faded_edges.dart';
import 'package:nyaplayer/features/shared/library_builder.dart';
import 'package:nyaplayer/features/shared/quality_badge.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

enum _PanelTab { cover, lyrics, queue }

/// Persistent "now playing" panel for wide windows (UI-05). It is the larger
/// of the two content areas; the expand button opens the immersive player.
class NowPlayingPanel extends ConsumerStatefulWidget {
  const NowPlayingPanel({super.key});

  @override
  ConsumerState<NowPlayingPanel> createState() => _NowPlayingPanelState();
}

class _NowPlayingPanelState extends ConsumerState<NowPlayingPanel> {
  _PanelTab _tab = _PanelTab.cover;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final track = ref.watch(queueProvider.select((s) => s.current));

    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Card.filled(
          margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
          color: scheme.surface,
          shape: RoundedRectangleBorder(borderRadius: desktopCardRadius),
          clipBehavior: Clip.antiAlias,
          child: PlayerBackground(
            track: track,
            child: track == null
                ? EmptyState(
                    icon: Icons.music_off_outlined,
                    title: l10n.notPlaying,
                    body: l10n.notPlayingHint,
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 16, 12, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: _TitleBlock(track: track),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 4, right: 4),
                              child: LyricsQueueToggle(
                                allowNone: true,
                                selected: switch (_tab) {
                                  _PanelTab.cover => null,
                                  _PanelTab.lyrics => PlayerView.lyrics,
                                  _PanelTab.queue => PlayerView.queue,
                                },
                                onChanged: (view) => setState(
                                  () => _tab = switch (view) {
                                    null => _PanelTab.cover,
                                    PlayerView.lyrics => _PanelTab.lyrics,
                                    PlayerView.queue => _PanelTab.queue,
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.expandPlayer,
                              style: const ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              iconSize: 18,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints.tightFor(
                                width: 34,
                                height: 34,
                              ),
                              icon: const Icon(Icons.open_in_full),
                              onPressed: () => context.push('/now-playing'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: Durations.medium2,
                          child: switch (_tab) {
                            _PanelTab.cover => _CoverView(
                              key: const ValueKey('cover'),
                              track: track,
                              onLyrics: () =>
                                  setState(() => _tab = _PanelTab.lyrics),
                            ),
                            _PanelTab.lyrics => const FadedEdges(
                              key: ValueKey('lyrics'),
                              child: LyricsView(),
                            ),
                            _PanelTab.queue => const FadedEdges(
                              key: ValueKey('queue'),
                              child: QueueList(padding: FadedEdges.fadePadding),
                            ),
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SeekBar(duration: track.duration),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                        child: PlayerControlsRow(
                          track: track,
                          transport: const TransportControls(spacing: 12),
                          menuItems: [
                            PlayerMenuButton.equalizer(context),
                            PlayerMenuButton.songInfo(context, track),
                          ],
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

/// Title and artist in the top-left corner of the panel.
class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
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
    );
  }
}

/// Cover, the audio-format badge centred right below it, then three lyric
/// lines as wide as the cover.
class _CoverView extends ConsumerWidget {
  const _CoverView({super.key, required this.track, required this.onLyrics});

  final Track track;
  final VoidCallback onLyrics;

  static const _badgeHeight = 40.0;
  static const _gaps = 16.0 + 16;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineHeight = ref.watch(
      lyricsSettingsProvider.select((s) => s.lineHeight),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final room =
              constraints.maxHeight -
              _badgeHeight -
              LyricsLines.heightOf(context, lineHeight) -
              _gaps;
          final size = math.max(
            0.0,
            math.min(math.min(constraints.maxWidth, room), 520.0),
          );
          return Center(
            child: SizedBox(
              width: size,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: size,
                    child: PlayerArtwork(track: track, maxSize: size),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: _badgeHeight,
                    child: Center(child: QualityBadge(track: track)),
                  ),
                  const SizedBox(height: 16),
                  LyricsLines(track: track, onTap: onLyrics),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
