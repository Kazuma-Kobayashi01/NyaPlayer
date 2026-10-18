import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/library_providers.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/lyrics/lyrics_settings.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// Three lines of lyrics (previous, current, next), left-aligned, shown under
/// the cover. Tapping opens the full lyrics view.
class LyricsLines extends ConsumerWidget {
  const LyricsLines({super.key, required this.track, this.onTap});

  static double rowHeightOf(BuildContext context, double lineHeight) {
    final size = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16;
    return MediaQuery.textScalerOf(context).scale(size + 3) * lineHeight + 8;
  }

  static double heightOf(BuildContext context, double lineHeight) =>
      rowHeightOf(context, lineHeight) * 3;

  final Track track;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lyrics = ref.watch(lyricsProvider(track));
    final settings = ref.watch(lyricsSettingsProvider);
    final lineHeight = settings.lineHeight;
    final rowHeight = rowHeightOf(context, lineHeight);
    final height = rowHeight * 3;

    final dim = theme.textTheme.bodyLarge?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
      height: lineHeight,
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

    // Outgoing AnimatedSwitcher children must share the new height when text
    // scaling changes mid-transition; fixed old row heights can overflow.
    Widget line(String text, TextStyle? style) => Expanded(
      child: SizedBox(
        width: double.infinity,
        child: ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
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
                theme.textTheme.bodyLarge?.copyWith(
                  fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) + 3,
                  height: lineHeight,
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              line(
                settings.showTranslation &&
                        lyrics.lines[current].translation != null
                    ? lyrics.lines[current].translation!.replaceAll('\n', ' / ')
                    : textOf(current + 1),
                settings.showTranslation &&
                        lyrics.lines[current].translation != null
                    ? theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: lineHeight,
                      )
                    : dim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
