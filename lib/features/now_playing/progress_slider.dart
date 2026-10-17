import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/app/theme/theme_settings.dart';
import 'package:nyaplayer/l10n/app_localizations.dart';

String progressStyleLabel(ProgressStyle style, AppLocalizations l10n) =>
    switch (style) {
      ProgressStyle.material => l10n.progressMaterial,
      ProgressStyle.classic => l10n.progressClassic,
      ProgressStyle.slim => l10n.progressSlim,
      ProgressStyle.wave => l10n.progressWave,
    };

/// Visual variants share Slider's gestures, keyboard controls and semantics.
class ProgressSlider extends ConsumerWidget {
  const ProgressSlider({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(
      themeSettingsProvider.select((s) => s.progressStyle),
    );
    final base = SliderTheme.of(context);
    final sliderTheme = style == ProgressStyle.material
        ? base
        : base.copyWith(
            trackHeight: style == ProgressStyle.slim ? 2 : 4,
            trackGap: 0,
            trackShape: style == ProgressStyle.wave
                ? const _WaveTrack()
                : const RoundedRectSliderTrackShape(),
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: style == ProgressStyle.slim ? 5 : 7,
              elevation: 0,
              pressedElevation: 0,
            ),
          );
    return SliderTheme(
      data: sliderTheme,
      child: Slider(
        value: value,
        max: max,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}

/// Static decoration; no audio analysis or perpetual animation is involved.
class _WaveTrack extends RoundedRectSliderTrackShape {
  const _WaveTrack();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final canvas = context.canvas;
    final active = ColorTween(
      begin: sliderTheme.disabledActiveTrackColor,
      end: sliderTheme.activeTrackColor,
    ).evaluate(enableAnimation)!;
    final inactive = ColorTween(
      begin: sliderTheme.disabledInactiveTrackColor,
      end: sliderTheme.inactiveTrackColor,
    ).evaluate(enableAnimation)!;
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final rtl = textDirection == TextDirection.rtl;
    final start = rtl ? rect.right : rect.left;
    final end = thumbCenter.dx.clamp(rect.left, rect.right);
    canvas.drawLine(
      Offset(end, rect.center.dy),
      Offset(rtl ? rect.left : rect.right, rect.center.dy),
      paint..color = inactive,
    );
    final distance = (end - start).abs();
    if (distance <= 0) return;
    final path = Path()..moveTo(start, rect.center.dy);
    for (var d = 1.0; d <= distance + 1; d += 1) {
      final x = math.min(d, distance);
      // Taper at the thumb so the wave joins it without a visible jump.
      final amplitude = math.min(3.0, (distance - x) / 3);
      path.lineTo(
        start + (rtl ? -x : x),
        rect.center.dy + math.sin(x * math.pi / 10) * amplitude,
      );
    }
    canvas.drawPath(
      path,
      paint
        ..color = active
        ..style = PaintingStyle.stroke,
    );
  }
}
