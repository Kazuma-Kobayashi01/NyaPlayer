/// `m:ss`, or `h:mm:ss` when an hour or longer.
String formatDuration(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

String formatSampleRate(int hz) {
  final khz = hz / 1000;
  return khz == khz.roundToDouble()
      ? '${khz.toInt()} kHz'
      : '${khz.toStringAsFixed(1)} kHz';
}
