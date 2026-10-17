import 'package:nyaplayer/data/library.dart';
import 'package:nyaplayer/domain/models.dart';

/// Fictional demo data used until the real scanner / database exists (M2).
final Library sampleLibrary = _build();

class _AlbumDef {
  const _AlbumDef({
    required this.title,
    required this.artist,
    required this.year,
    required this.seed,
    required this.codec,
    required this.sampleRate,
    required this.bitDepth,
    required this.bitrate,
    required this.tracks,
    this.folder,
    this.genre,
  });

  final String title;
  final String artist;
  final int year;
  final int seed;
  final String codec;
  final int sampleRate;
  final int bitDepth;
  final int bitrate;
  final String? folder;
  final String? genre;
  final List<_TrackDef> tracks;
}

class _TrackDef {
  const _TrackDef(this.title, this.seconds, {this.artist, this.lyrics});

  final String title;
  final int seconds;
  final String? artist;
  final _LyricsKind? lyrics;
}

enum _LyricsKind { synced, bilingual, plain }

const _syncedLines = [
  '夜色落在空荡荡的月台',
  '列车带走了最后的回响',
  'City lights are fading in the rain',
  'And I keep walking toward the sound',
  '',
  '风把名字吹向很远的地方',
  '我在原地等一个答案',
  'Hold on, hold on to the morning',
  'We were never meant to be alone',
  '星光慢慢落进你的眼睛',
  'Sing it softly, let it carry on',
];

const _jpLines = [
  '透明な季節の中で',
  '君の声が揺れていた',
  '窓の向こうの空は',
  'どこまでも青かった',
  '',
  '忘れないよ この景色を',
  '手を伸ばせば届きそうで',
  'さよならの代わりに',
  '微笑んで歩き出した',
];

const _zhTranslations = [
  '在透明的季节里',
  '你的声音在摇曳',
  '窗外的天空',
  '一直蔚蓝到尽头',
  '',
  '我不会忘记这片景色',
  '仿佛伸出手就能触到',
  '代替一声再见',
  '微笑着迈出了脚步',
];

const _plainLyrics = '''
Paper moons above the river
Folding light into a boat
Every window knows your name now
Every road is a quiet note

Hold the lantern, hold it steady
We will find the way back home''';

String _stamp(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  final cs = ((d.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
  return '[$m:$s.$cs]';
}

String _lrc(
  List<String> lines,
  int totalSeconds, {
  List<String>? translations,
}) {
  final step = (totalSeconds - 20) / lines.length;
  final buf = StringBuffer('[ti:Demo]\n[ar:Demo]\n');
  for (var i = 0; i < lines.length; i++) {
    final t = _stamp(Duration(milliseconds: (8000 + step * i * 1000).round()));
    buf.writeln('$t${lines[i]}');
    if (translations != null && lines[i].isNotEmpty) {
      buf.writeln('$t${translations[i]}');
    }
  }
  return buf.toString();
}

String? _lyricsFor(_LyricsKind? kind, int seconds) {
  switch (kind) {
    case null:
      return null;
    case _LyricsKind.synced:
      return _lrc(_syncedLines, seconds);
    case _LyricsKind.bilingual:
      return _lrc(_jpLines, seconds, translations: _zhTranslations);
    case _LyricsKind.plain:
      return _plainLyrics;
  }
}

Library _build() {
  const defs = <_AlbumDef>[
    _AlbumDef(
      title: 'Neon Harbor',
      artist: 'Aurora Lane',
      year: 2023,
      seed: 0xFF6750A4,
      codec: 'FLAC',
      sampleRate: 44100,
      bitDepth: 16,
      bitrate: 920,
      genre: 'Synth-pop',
      tracks: [
        _TrackDef('Harbor Lights', 214, lyrics: _LyricsKind.synced),
        _TrackDef('Midnight Ferry', 247, lyrics: _LyricsKind.synced),
        _TrackDef('Static Bloom', 198),
        _TrackDef('The Glass Pier', 305, lyrics: _LyricsKind.synced),
        _TrackDef('Afterglow', 262),
      ],
    ),
    _AlbumDef(
      title: '夜航',
      artist: '星河电台',
      year: 2022,
      seed: 0xFF006A6A,
      codec: 'FLAC',
      sampleRate: 96000,
      bitDepth: 24,
      bitrate: 2400,
      genre: 'Indie',
      tracks: [
        _TrackDef('晚安，城市', 231, lyrics: _LyricsKind.synced),
        _TrackDef('夜航船', 276, lyrics: _LyricsKind.synced),
        _TrackDef('远方的灯塔', 255),
        _TrackDef('回声', 189, lyrics: _LyricsKind.plain),
      ],
    ),
    _AlbumDef(
      title: '透明な季節',
      artist: '水無月ひかり',
      year: 2021,
      seed: 0xFFB3261E,
      codec: 'FLAC',
      sampleRate: 192000,
      bitDepth: 24,
      bitrate: 4600,
      genre: 'J-Pop',
      tracks: [
        _TrackDef('透明な季節', 238, lyrics: _LyricsKind.bilingual),
        _TrackDef('夏の終わりに', 221, lyrics: _LyricsKind.bilingual),
        _TrackDef('風の手紙', 264),
        _TrackDef('Blue Hour', 207, lyrics: _LyricsKind.synced),
      ],
    ),
    _AlbumDef(
      title: 'Live at Tidepool',
      artist: 'The Tidepool Band',
      year: 2019,
      seed: 0xFF386A20,
      codec: 'MP3',
      sampleRate: 44100,
      bitDepth: 16,
      bitrate: 320,
      genre: 'Rock',
      tracks: [
        _TrackDef('Opening Tide', 312),
        _TrackDef('Salt & Wire', 288, lyrics: _LyricsKind.synced),
        _TrackDef('Lighthouse Blues', 403),
        _TrackDef('Encore (Live)', 356),
      ],
    ),
    _AlbumDef(
      title: 'Paper Moons',
      artist: 'Marlow & Finch',
      year: 2020,
      seed: 0xFF8B5000,
      codec: 'FLAC',
      sampleRate: 48000,
      bitDepth: 24,
      bitrate: 1500,
      genre: 'Folk',
      tracks: [
        _TrackDef('Paper Moons', 226, lyrics: _LyricsKind.plain),
        _TrackDef('Lantern Song', 241, lyrics: _LyricsKind.synced),
        _TrackDef('Orchard Road', 199),
        _TrackDef('Homeward', 273),
      ],
    ),
    _AlbumDef(
      title: '夏日合辑 2024',
      artist: 'Various Artists',
      year: 2024,
      seed: 0xFF00629D,
      codec: 'FLAC',
      sampleRate: 44100,
      bitDepth: 16,
      bitrate: 900,
      folder: '/Music/Singles',
      genre: 'Pop',
      tracks: [
        _TrackDef(
          'Sunburn',
          203,
          artist: 'Aurora Lane',
          lyrics: _LyricsKind.synced,
        ),
        _TrackDef('海盐汽水', 218, artist: '星河电台'),
        _TrackDef('Summer Haze', 244, artist: 'Marlow & Finch'),
        _TrackDef('ひまわり', 232, artist: '水無月ひかり', lyrics: _LyricsKind.bilingual),
        _TrackDef('Last Train Home', 267, artist: 'The Tidepool Band'),
      ],
    ),
  ];

  final tracks = <Track>[];
  final albums = <Album>[];
  var trackId = 1;
  final base = DateTime(2026, 9, 1);

  for (var a = 0; a < defs.length; a++) {
    final d = defs[a];
    final albumId = a + 1;
    albums.add(
      Album(
        id: albumId,
        title: d.title,
        artist: d.artist,
        year: d.year,
        coverSeed: d.seed,
      ),
    );
    final folder = d.folder ?? '/Music/${d.artist}/${d.title}';
    for (var i = 0; i < d.tracks.length; i++) {
      final t = d.tracks[i];
      final ext = d.codec == 'MP3' ? 'mp3' : 'flac';
      tracks.add(
        Track(
          id: trackId,
          title: t.title,
          artist: t.artist ?? d.artist,
          albumId: albumId,
          album: d.title,
          trackNo: i + 1,
          duration: Duration(seconds: t.seconds),
          path: '$folder/${(i + 1).toString().padLeft(2, '0')} ${t.title}.$ext',
          codec: d.codec,
          sampleRate: d.sampleRate,
          bitDepth: d.bitDepth,
          bitrateKbps: d.bitrate,
          year: d.year,
          genre: d.genre,
          lyrics: _lyricsFor(t.lyrics, t.seconds),
          addedAt: base.add(Duration(days: a * 3, hours: i)),
          coverSeed: d.seed,
        ),
      );
      trackId++;
    }
  }
  return Library(tracks: tracks, albums: albums);
}
