import 'package:nyaplayer/data/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/domain/models.dart';
import 'package:nyaplayer/features/now_playing/turntable_cover.dart';
import 'package:nyaplayer/features/shared/cover_art.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

enum CoverShape { square, disc, turntable }

/// Player cover style, chosen in settings.
final coverShapeProvider = NotifierProvider<CoverShapeController, CoverShape>(
  CoverShapeController.new,
);

class CoverShapeController extends Notifier<CoverShape> {
  @override
  CoverShape build() {
    final store = ref.read(settingsStoreProvider);
    listenSelf(
      skipInitial<CoverShape>(
        (_, next) => store.put('player.coverShape', next.name),
      ),
    );
    return enumByName(
      CoverShape.values,
      store.get('player.coverShape'),
      CoverShape.square,
    );
  }

  void set(CoverShape shape) => state = shape;
}

/// The large cover shown by the players: a rounded square, a disc that spins
/// while music plays, or a record player with the cover as the record's label.
class PlayerArtwork extends ConsumerWidget {
  const PlayerArtwork({
    super.key,
    required this.track,
    this.maxSize = 440,
    this.heroTag,
  });

  final Track track;
  final double maxSize;

  /// Hero tag for the square cover (the other shapes do not fly).
  final Object? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shape = ref.watch(coverShapeProvider);
    final playing = ref.watch(queueProvider.select((s) => s.playing));
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxSize, maxHeight: maxSize),
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedSwitcher(
            duration: Durations.medium2,
            switchInCurve: Easing.emphasizedDecelerate,
            child: switch (shape) {
              CoverShape.square => _SquareCover(
                key: ValueKey(('square', track.albumId)),
                track: track,
                heroTag: heroTag,
              ),
              CoverShape.disc => _SpinningDisc(
                key: ValueKey(('disc', track.albumId)),
                track: track,
                spinning: playing,
              ),
              // One turntable for every song: the arm lifts and comes down
              // when the song changes, instead of a whole new player fading
              // in.
              CoverShape.turntable => TurntableCover(
                key: const ValueKey('turntable'),
                track: track,
                playing: playing,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _SquareCover extends StatelessWidget {
  const _SquareCover({super.key, required this.track, this.heroTag});

  final Track track;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 6,
      shadowColor: scheme.shadow,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: CoverArt(
        seed: track.coverSeed,
        source: track.cover,
        highResolution: true,
        radius: 28,
        heroTag: heroTag,
      ),
    );
  }
}

class _SpinningDisc extends StatefulWidget {
  const _SpinningDisc({super.key, required this.track, required this.spinning});

  final Track track;
  final bool spinning;

  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc>
    with SingleTickerProviderStateMixin {
  /// One full turn every 20 seconds, like a slow record.
  late final AnimationController _turns = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _turns.repeat();
  }

  @override
  void didUpdateWidget(_SpinningDisc old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_turns.isAnimating) {
      _turns.repeat();
    } else if (!widget.spinning && _turns.isAnimating) {
      _turns.stop(); // keeps the current angle; no ticker while paused
    }
  }

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 6,
      shadowColor: scheme.shadow,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: RotationTransition(
        turns: _turns,
        child: CoverArt(
          seed: widget.track.coverSeed,
          source: widget.track.cover,
          highResolution: true,
          radius: 10000,
        ),
      ),
    );
  }
}
