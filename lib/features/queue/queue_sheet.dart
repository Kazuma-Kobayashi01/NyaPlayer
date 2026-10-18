import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/features/queue/queue_list.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';
import 'package:nyaplayer/services/player/queue_controller.dart';

/// Drives a [QueueSheet] from vertical drags. `controller.value` is 0 when the
/// sheet is closed and 1 when it covers the page; [travel] is the distance in
/// pixels between the two.
class QueueSheetDrag {
  QueueSheetDrag(this.controller);

  final AnimationController controller;
  double travel = 1;

  static const _flingVelocity = 400.0;

  bool get isOpen => controller.value > 0;

  /// [dy] > 0 moves the sheet down (towards closed).
  void update(double dy) {
    controller.value -= dy / travel;
  }

  /// Settles open or closed from the release velocity (px/s, > 0 downwards).
  void end(double velocity) {
    if (velocity <= -_flingVelocity) {
      open(velocity);
    } else if (velocity >= _flingVelocity) {
      close(velocity);
    } else if (controller.value >= 0.5) {
      open(velocity);
    } else {
      close(velocity);
    }
  }

  // A spring that starts with the finger's velocity, so the sheet carries on
  // at the speed it was thrown instead of restarting a fixed-length curve.
  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 650,
    ratio: 1.0,
  );

  void _settle(double target, double velocity) {
    controller
        .animateWith(
          SpringSimulation(
            _spring,
            controller.value,
            target,
            // Dragging down (velocity > 0) lowers the value.
            -velocity / travel,
          ),
        )
        // The spring stops within its tolerance; land exactly so a closed
        // sheet is really at 0 and removed.
        .whenCompleteOrCancel(() {
          if ((controller.value - target).abs() < 0.01) {
            controller.value = target;
          }
        });
  }

  void open([double velocity = 0]) => _settle(1, velocity);

  void close([double velocity = 0]) => _settle(0, velocity);
}

/// Full-height play queue that slides up over the phone player. Dragging the
/// header down, or pulling the list down once it is scrolled to the top,
/// closes it.
class QueueSheet extends ConsumerStatefulWidget {
  const QueueSheet({super.key, required this.drag});

  final QueueSheetDrag drag;

  @override
  ConsumerState<QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends ConsumerState<QueueSheet> {
  /// True while the list is pulled down past its top and moves the sheet.
  bool _pulling = false;

  bool _onScroll(ScrollNotification n) {
    final drag = widget.drag;
    if (n is OverscrollNotification &&
        n.overscroll < 0 &&
        n.dragDetails != null) {
      _pulling = true;
      drag.update(-n.overscroll);
    } else if (n is ScrollUpdateNotification &&
        _pulling &&
        n.dragDetails != null) {
      // Dragging back up while the sheet is lowered raises it first.
      drag.update(-(n.scrollDelta ?? 0));
    } else if (n is ScrollEndNotification && _pulling) {
      _pulling = false;
      drag.end(n.dragDetails?.primaryVelocity ?? 0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = ref.watch(queueProvider.select((s) => s.queue.length));
    final drag = widget.drag;

    return Material(
      color: scheme.surfaceContainerLow,
      elevation: 3,
      shadowColor: scheme.shadow,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        // Header and empty-state drags; the list handles its own area.
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (d) => drag.update(d.delta.dy),
        onVerticalDragEnd: (d) => drag.end(d.primaryVelocity ?? 0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.queue, style: theme.textTheme.titleLarge),
                        Text(
                          l10n.songCount(count),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.close,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: drag.close,
                  ),
                ],
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: QueueList(
                  // Clamping so pulling past the top reports overscroll
                  // instead of bouncing.
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
