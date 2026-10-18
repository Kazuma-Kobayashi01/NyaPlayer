import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport, RenderBox;
import 'package:nyaplayer/app/theme/app_theme.dart' show FontTuning;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/lyrics/lyrics_settings.dart';
import 'package:nyaplayer/features/shared/faded_edges.dart';
import 'package:nyaplayer/features/shared/library_builder.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// Scrolling lyrics (LRC-05/06/07/08/10). Synced lyrics highlight and centre the
/// current line; tapping a line seeks to it; manual scrolling pauses following
/// for [followResumeDelay].
class LyricsView extends ConsumerStatefulWidget {
  const LyricsView({super.key});

  static const followResumeDelay = Duration(seconds: 3);

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  final _scroll = ScrollController();
  List<GlobalKey> _keys = const [];
  int? _trackId;
  int _active = -1;
  DateTime _followAfter = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _resetFor(Track track, Lyrics lyrics) {
    _trackId = track.id;
    final position = ref.read(positionProvider).value ?? Duration.zero;
    _active = lyrics.synced ? lyrics.indexAt(position) : -1;
    _keys = List.generate(lyrics.lines.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      // Opening lyrics while paused must still reveal and highlight the
      // current line; no new position event is guaranteed in that case.
      final activeContext = _active >= 0 && _active < _keys.length
          ? _keys[_active].currentContext
          : null;
      if (activeContext != null) {
        _revealIn(activeContext);
        return;
      }
      final position = _scroll.position;
      // Before the first line is sung, show it in the upper third instead of
      // leaving the top half of the pane empty with the text cut off below.
      final viewport = position.viewportDimension;
      final start = lyrics.synced ? viewport / 2.2 - viewport * 0.3 : 0.0;
      _scroll.jumpTo(start.clamp(0.0, position.maxScrollExtent));
    });
  }

  void _onPosition(Lyrics lyrics, Duration position) {
    final index = lyrics.indexAt(position);
    if (index == _active) return;
    setState(() => _active = index);
    if (index < 0 || DateTime.now().isBefore(_followAfter)) return;
    _revealActive();
  }

  void _revealActive() {
    final index = _active;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index < 0 || index >= _keys.length) return;
      final context = _keys[index].currentContext;
      if (context == null) return;
      _revealIn(
        context,
        duration: Durations.medium2,
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Centres [target] in this view's own scrollable.
  ///
  /// `Scrollable.ensureVisible` would also scroll every scrollable around the
  /// lyrics, including the player's horizontal page view: with the lyrics
  /// page built off screen, each new line pulled the player over to it.
  void _revealIn(
    BuildContext target, {
    Duration? duration,
    Curve curve = Curves.ease,
  }) {
    final render = target.findRenderObject();
    if (render is! RenderBox || !render.attached || !render.hasSize) return;
    if (!_scroll.hasClients) return;
    final viewport = RenderAbstractViewport.maybeOf(render);
    if (viewport == null) return;
    final position = _scroll.position;
    final offset = viewport
        .getOffsetToReveal(render, 0.5)
        .offset
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (duration == null) {
      position.jumpTo(offset);
    } else {
      position.animateTo(offset, duration: duration, curve: curve);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final track = ref.watch(queueProvider.select((s) => s.current));
    if (track == null) {
      return EmptyState(icon: Icons.lyrics_outlined, title: l10n.noLyrics);
    }
    final lyrics = ref.watch(lyricsProvider(track));
    if (lyrics.isEmpty) {
      return EmptyState(icon: Icons.lyrics_outlined, title: l10n.noLyrics);
    }
    final settings = ref.watch(lyricsSettingsProvider);
    ref.listen(lyricsSettingsProvider, (previous, next) {
      if (previous?.fontSize != next.fontSize ||
          previous?.lineHeight != next.lineHeight ||
          previous?.centered != next.centered ||
          previous?.showTranslation != next.showTranslation) {
        _revealActive();
      }
    });
    if (_trackId != track.id || _keys.length != lyrics.lines.length) {
      _resetFor(track, lyrics);
    }
    if (lyrics.synced) {
      ref.listen(
        positionProvider,
        (_, next) => _onPosition(lyrics, next.value ?? Duration.zero),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final edge = constraints.maxHeight / 2.2;
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollStartNotification && n.dragDetails != null) {
              _followAfter = DateTime.now().add(LyricsView.followResumeDelay);
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: _scroll,
            padding: EdgeInsets.symmetric(
              vertical: lyrics.synced ? edge : FadedEdges.fadeExtent + 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < lyrics.lines.length; i++)
                  _LyricTile(
                    key: _keys[i],
                    line: lyrics.lines[i],
                    synced: lyrics.synced,
                    active: i == _active,
                    settings: settings,
                    onTap: lyrics.synced
                        ? () {
                            _followAfter = DateTime.fromMillisecondsSinceEpoch(
                              0,
                            );
                            ref
                                .read(queueProvider.notifier)
                                .seek(lyrics.lines[i].start);
                          }
                        : null,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LyricTile extends StatelessWidget {
  const _LyricTile({
    super.key,
    required this.line,
    required this.synced,
    required this.active,
    required this.settings,
    required this.onTap,
  });

  final LyricLine line;
  final bool synced;
  final bool active;
  final LyricsSettings settings;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size =
        settings.fontSize * (theme.extension<FontTuning>()?.sizeFactor ?? 1.0);
    final base = theme.textTheme.bodyLarge?.copyWith(
      // The line being sung is two sizes larger than the 1.15x step alone.
      fontSize: synced && active ? size * 1.15 + 3 : size,
      height: settings.lineHeight,
    );
    final color = active || !synced
        ? scheme.onSurface
        : scheme.onSurfaceVariant;
    final text = line.isInterlude ? '•••' : line.text;
    final align = settings.centered ? TextAlign.center : TextAlign.start;
    final translation = settings.showTranslation ? line.translation : null;
    final translationStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: (size * 0.82).clamp(LyricsSettings.minFontSize, size),
      height: settings.lineHeight,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedOpacity(
        opacity: active || !synced ? 1 : 0.55,
        duration: Durations.medium2,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical:
                6 * settings.lineHeight / LyricsSettings.defaultLineHeight,
          ),
          child: Column(
            crossAxisAlignment: settings.centered
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              AnimatedDefaultTextStyle(
                // Settings edits apply their new geometry before recentering;
                // playback highlighting still animates between lyric lines.
                key: ValueKey((settings.fontSize, settings.lineHeight)),
                style: (base ?? const TextStyle()).copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: align,
                duration: Durations.medium2,
                curve: Easing.emphasizedDecelerate,
                child: Text(text),
              ),
              if (translation != null) ...[
                const SizedBox(height: 4),
                Text(
                  translation,
                  textAlign: align,
                  style: translationStyle?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
