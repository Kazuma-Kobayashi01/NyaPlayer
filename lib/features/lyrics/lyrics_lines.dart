import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// Three lines of lyrics (previous, current, next), left-aligned, shown under
/// the cover. Tapping opens the full lyrics view.
class LyricsLines extends ConsumerWidget {
  const LyricsLines({super.key, required this.track, this.onTap});

  static const lineHeight = 30.0;
  static const height = lineHeight * 3;

  final Track track;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lyrics = ref.watch(lyricsProvider(track));

    final dim = theme.textTheme.bodyLarge?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
    );

    if (lyrics.isEmpty) {
      return SizedBox(
        height: height,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(l10n.noLyrics, style: dim),
        ),
      );
    }

    var current = 0;
    if (lyrics.synced) {
      final position = ref.watch(positionProvider).value ?? Duration.zero;
      current = lyrics.indexAt(position).clamp(0, lyrics.lines.length - 1);
    }
    String textOf(int i) {
      if (i < 0 || i >= lyrics.lines.length) return '';
      final line = lyrics.lines[i];
      return line.isInterlude ? '•••' : line.text;
    }

    Widget line(String text, TextStyle? style) => SizedBox(
      height: lineHeight,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: AnimatedSwitcher(
          duration: Durations.medium2,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.centerLeft,
            children: [...previous, ?current],
          ),
          child: Column(
            key: ValueKey(current),
            children: [
              line(textOf(current - 1), dim),
              line(
                textOf(current),
                theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              line(textOf(current + 1), dim),
            ],
          ),
        ),
      ),
    );
  }
}
