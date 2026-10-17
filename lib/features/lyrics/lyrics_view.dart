import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/lyrics/lyrics_settings.dart';
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
    _active = -1;
    _keys = List.generate(lyrics.lines.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  void _onPosition(Lyrics lyrics, Duration position) {
    final index = lyrics.indexAt(position);
    if (index == _active) return;
    setState(() => _active = index);
    if (index < 0 || DateTime.now().isBefore(_followAfter)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index >= _keys.length) return;
      final context = _keys[index].currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: Durations.medium2,
        curve: Curves.easeOutCubic,
      );
    });
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
            padding: EdgeInsets.symmetric(vertical: lyrics.synced ? edge : 16),
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
    final size = settings.fontSize;
    final base = theme.textTheme.bodyLarge?.copyWith(
      fontSize: synced && active ? size * 1.15 : size,
      height: 1.35,
    );
    final color = active || !synced
        ? scheme.onSurface
        : scheme.onSurfaceVariant;
    final text = line.isInterlude ? '•••' : line.text;
    final align = settings.centered ? TextAlign.center : TextAlign.start;
    final translation = settings.showTranslation ? line.translation : null;
    final translationStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: (size * 0.82).clamp(LyricsSettings.minFontSize, size),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedOpacity(
        opacity: active || !synced ? 1 : 0.55,
        duration: Durations.medium2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: settings.centered
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              AnimatedDefaultTextStyle(
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
