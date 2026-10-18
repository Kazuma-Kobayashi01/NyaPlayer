// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AlbumsTable extends Albums with TableInfo<$AlbumsTable, Album> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _albumKeyMeta = const VerificationMeta(
    'albumKey',
  );
  @override
  late final GeneratedColumn<String> albumKey = GeneratedColumn<String>(
    'album_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _albumArtistMeta = const VerificationMeta(
    'albumArtist',
  );
  @override
  late final GeneratedColumn<String> albumArtist = GeneratedColumn<String>(
    'album_artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverStateMeta = const VerificationMeta(
    'coverState',
  );
  @override
  late final GeneratedColumn<int> coverState = GeneratedColumn<int>(
    'cover_state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _coverTrackIdMeta = const VerificationMeta(
    'coverTrackId',
  );
  @override
  late final GeneratedColumn<int> coverTrackId = GeneratedColumn<int>(
    'cover_track_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    albumKey,
    title,
    albumArtist,
    year,
    coverState,
    coverTrackId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'albums';
  @override
  VerificationContext validateIntegrity(
    Insertable<Album> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('album_key')) {
      context.handle(
        _albumKeyMeta,
        albumKey.isAcceptableOrUnknown(data['album_key']!, _albumKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_albumKeyMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('album_artist')) {
      context.handle(
        _albumArtistMeta,
        albumArtist.isAcceptableOrUnknown(
          data['album_artist']!,
          _albumArtistMeta,
        ),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('cover_state')) {
      context.handle(
        _coverStateMeta,
        coverState.isAcceptableOrUnknown(data['cover_state']!, _coverStateMeta),
      );
    }
    if (data.containsKey('cover_track_id')) {
      context.handle(
        _coverTrackIdMeta,
        coverTrackId.isAcceptableOrUnknown(
          data['cover_track_id']!,
          _coverTrackIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Album map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Album(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      albumKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_key'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      albumArtist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_artist'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      coverState: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cover_state'],
      )!,
      coverTrackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cover_track_id'],
      ),
    );
  }

  @override
  $AlbumsTable createAlias(String alias) {
    return $AlbumsTable(attachedDatabase, alias);
  }
}

class Album extends DataClass implements Insertable<Album> {
  final int id;
  final String albumKey;
  final String title;
  final String albumArtist;
  final int? year;

  /// 0 unknown, 1 has cover, 2 no cover (TECH_SPEC §7.3).
  final int coverState;
  final int? coverTrackId;
  const Album({
    required this.id,
    required this.albumKey,
    required this.title,
    required this.albumArtist,
    this.year,
    required this.coverState,
    this.coverTrackId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['album_key'] = Variable<String>(albumKey);
    map['title'] = Variable<String>(title);
    map['album_artist'] = Variable<String>(albumArtist);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    map['cover_state'] = Variable<int>(coverState);
    if (!nullToAbsent || coverTrackId != null) {
      map['cover_track_id'] = Variable<int>(coverTrackId);
    }
    return map;
  }

  AlbumsCompanion toCompanion(bool nullToAbsent) {
    return AlbumsCompanion(
      id: Value(id),
      albumKey: Value(albumKey),
      title: Value(title),
      albumArtist: Value(albumArtist),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      coverState: Value(coverState),
      coverTrackId: coverTrackId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverTrackId),
    );
  }

  factory Album.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Album(
      id: serializer.fromJson<int>(json['id']),
      albumKey: serializer.fromJson<String>(json['albumKey']),
      title: serializer.fromJson<String>(json['title']),
      albumArtist: serializer.fromJson<String>(json['albumArtist']),
      year: serializer.fromJson<int?>(json['year']),
      coverState: serializer.fromJson<int>(json['coverState']),
      coverTrackId: serializer.fromJson<int?>(json['coverTrackId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'albumKey': serializer.toJson<String>(albumKey),
      'title': serializer.toJson<String>(title),
      'albumArtist': serializer.toJson<String>(albumArtist),
      'year': serializer.toJson<int?>(year),
      'coverState': serializer.toJson<int>(coverState),
      'coverTrackId': serializer.toJson<int?>(coverTrackId),
    };
  }

  Album copyWith({
    int? id,
    String? albumKey,
    String? title,
    String? albumArtist,
    Value<int?> year = const Value.absent(),
    int? coverState,
    Value<int?> coverTrackId = const Value.absent(),
  }) => Album(
    id: id ?? this.id,
    albumKey: albumKey ?? this.albumKey,
    title: title ?? this.title,
    albumArtist: albumArtist ?? this.albumArtist,
    year: year.present ? year.value : this.year,
    coverState: coverState ?? this.coverState,
    coverTrackId: coverTrackId.present ? coverTrackId.value : this.coverTrackId,
  );
  Album copyWithCompanion(AlbumsCompanion data) {
    return Album(
      id: data.id.present ? data.id.value : this.id,
      albumKey: data.albumKey.present ? data.albumKey.value : this.albumKey,
      title: data.title.present ? data.title.value : this.title,
      albumArtist: data.albumArtist.present
          ? data.albumArtist.value
          : this.albumArtist,
      year: data.year.present ? data.year.value : this.year,
      coverState: data.coverState.present
          ? data.coverState.value
          : this.coverState,
      coverTrackId: data.coverTrackId.present
          ? data.coverTrackId.value
          : this.coverTrackId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Album(')
          ..write('id: $id, ')
          ..write('albumKey: $albumKey, ')
          ..write('title: $title, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('year: $year, ')
          ..write('coverState: $coverState, ')
          ..write('coverTrackId: $coverTrackId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    albumKey,
    title,
    albumArtist,
    year,
    coverState,
    coverTrackId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Album &&
          other.id == this.id &&
          other.albumKey == this.albumKey &&
          other.title == this.title &&
          other.albumArtist == this.albumArtist &&
          other.year == this.year &&
          other.coverState == this.coverState &&
          other.coverTrackId == this.coverTrackId);
}

class AlbumsCompanion extends UpdateCompanion<Album> {
  final Value<int> id;
  final Value<String> albumKey;
  final Value<String> title;
  final Value<String> albumArtist;
  final Value<int?> year;
  final Value<int> coverState;
  final Value<int?> coverTrackId;
  const AlbumsCompanion({
    this.id = const Value.absent(),
    this.albumKey = const Value.absent(),
    this.title = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.year = const Value.absent(),
    this.coverState = const Value.absent(),
    this.coverTrackId = const Value.absent(),
  });
  AlbumsCompanion.insert({
    this.id = const Value.absent(),
    required String albumKey,
    this.title = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.year = const Value.absent(),
    this.coverState = const Value.absent(),
    this.coverTrackId = const Value.absent(),
  }) : albumKey = Value(albumKey);
  static Insertable<Album> custom({
    Expression<int>? id,
    Expression<String>? albumKey,
    Expression<String>? title,
    Expression<String>? albumArtist,
    Expression<int>? year,
    Expression<int>? coverState,
    Expression<int>? coverTrackId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (albumKey != null) 'album_key': albumKey,
      if (title != null) 'title': title,
      if (albumArtist != null) 'album_artist': albumArtist,
      if (year != null) 'year': year,
      if (coverState != null) 'cover_state': coverState,
      if (coverTrackId != null) 'cover_track_id': coverTrackId,
    });
  }

  AlbumsCompanion copyWith({
    Value<int>? id,
    Value<String>? albumKey,
    Value<String>? title,
    Value<String>? albumArtist,
    Value<int?>? year,
    Value<int>? coverState,
    Value<int?>? coverTrackId,
  }) {
    return AlbumsCompanion(
      id: id ?? this.id,
      albumKey: albumKey ?? this.albumKey,
      title: title ?? this.title,
      albumArtist: albumArtist ?? this.albumArtist,
      year: year ?? this.year,
      coverState: coverState ?? this.coverState,
      coverTrackId: coverTrackId ?? this.coverTrackId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (albumKey.present) {
      map['album_key'] = Variable<String>(albumKey.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (albumArtist.present) {
      map['album_artist'] = Variable<String>(albumArtist.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (coverState.present) {
      map['cover_state'] = Variable<int>(coverState.value);
    }
    if (coverTrackId.present) {
      map['cover_track_id'] = Variable<int>(coverTrackId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumsCompanion(')
          ..write('id: $id, ')
          ..write('albumKey: $albumKey, ')
          ..write('title: $title, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('year: $year, ')
          ..write('coverState: $coverState, ')
          ..write('coverTrackId: $coverTrackId')
          ..write(')'))
        .toString();
  }
}

class $TracksTable extends Tracks with TableInfo<$TracksTable, Track> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mtimeMeta = const VerificationMeta('mtime');
  @override
  late final GeneratedColumn<int> mtime = GeneratedColumn<int>(
    'mtime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _albumArtistMeta = const VerificationMeta(
    'albumArtist',
  );
  @override
  late final GeneratedColumn<String> albumArtist = GeneratedColumn<String>(
    'album_artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<int> albumId = GeneratedColumn<int>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES albums (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _trackNoMeta = const VerificationMeta(
    'trackNo',
  );
  @override
  late final GeneratedColumn<int> trackNo = GeneratedColumn<int>(
    'track_no',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discNoMeta = const VerificationMeta('discNo');
  @override
  late final GeneratedColumn<int> discNo = GeneratedColumn<int>(
    'disc_no',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sampleRateMeta = const VerificationMeta(
    'sampleRate',
  );
  @override
  late final GeneratedColumn<int> sampleRate = GeneratedColumn<int>(
    'sample_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bitDepthMeta = const VerificationMeta(
    'bitDepth',
  );
  @override
  late final GeneratedColumn<int> bitDepth = GeneratedColumn<int>(
    'bit_depth',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bitrateMeta = const VerificationMeta(
    'bitrate',
  );
  @override
  late final GeneratedColumn<int> bitrate = GeneratedColumn<int>(
    'bitrate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelsMeta = const VerificationMeta(
    'channels',
  );
  @override
  late final GeneratedColumn<int> channels = GeneratedColumn<int>(
    'channels',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codecMeta = const VerificationMeta('codec');
  @override
  late final GeneratedColumn<String> codec = GeneratedColumn<String>(
    'codec',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hasEmbeddedLyricsMeta = const VerificationMeta(
    'hasEmbeddedLyrics',
  );
  @override
  late final GeneratedColumn<bool> hasEmbeddedLyrics = GeneratedColumn<bool>(
    'has_embedded_lyrics',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_embedded_lyrics" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sidecarLrcPathMeta = const VerificationMeta(
    'sidecarLrcPath',
  );
  @override
  late final GeneratedColumn<String> sidecarLrcPath = GeneratedColumn<String>(
    'sidecar_lrc_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderCoverPathMeta = const VerificationMeta(
    'folderCoverPath',
  );
  @override
  late final GeneratedColumn<String> folderCoverPath = GeneratedColumn<String>(
    'folder_cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataErrorMeta = const VerificationMeta(
    'metadataError',
  );
  @override
  late final GeneratedColumn<bool> metadataError = GeneratedColumn<bool>(
    'metadata_error',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("metadata_error" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _playCountMeta = const VerificationMeta(
    'playCount',
  );
  @override
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
    'play_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<int> lastPlayedAt = GeneratedColumn<int>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    path,
    size,
    mtime,
    title,
    artist,
    albumArtist,
    album,
    albumId,
    trackNo,
    discNo,
    year,
    genre,
    durationMs,
    sampleRate,
    bitDepth,
    bitrate,
    channels,
    codec,
    hasEmbeddedLyrics,
    sidecarLrcPath,
    folderCoverPath,
    metadataError,
    addedAt,
    playCount,
    lastPlayedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Track> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    }
    if (data.containsKey('mtime')) {
      context.handle(
        _mtimeMeta,
        mtime.isAcceptableOrUnknown(data['mtime']!, _mtimeMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('album_artist')) {
      context.handle(
        _albumArtistMeta,
        albumArtist.isAcceptableOrUnknown(
          data['album_artist']!,
          _albumArtistMeta,
        ),
      );
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    if (data.containsKey('track_no')) {
      context.handle(
        _trackNoMeta,
        trackNo.isAcceptableOrUnknown(data['track_no']!, _trackNoMeta),
      );
    }
    if (data.containsKey('disc_no')) {
      context.handle(
        _discNoMeta,
        discNo.isAcceptableOrUnknown(data['disc_no']!, _discNoMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('sample_rate')) {
      context.handle(
        _sampleRateMeta,
        sampleRate.isAcceptableOrUnknown(data['sample_rate']!, _sampleRateMeta),
      );
    }
    if (data.containsKey('bit_depth')) {
      context.handle(
        _bitDepthMeta,
        bitDepth.isAcceptableOrUnknown(data['bit_depth']!, _bitDepthMeta),
      );
    }
    if (data.containsKey('bitrate')) {
      context.handle(
        _bitrateMeta,
        bitrate.isAcceptableOrUnknown(data['bitrate']!, _bitrateMeta),
      );
    }
    if (data.containsKey('channels')) {
      context.handle(
        _channelsMeta,
        channels.isAcceptableOrUnknown(data['channels']!, _channelsMeta),
      );
    }
    if (data.containsKey('codec')) {
      context.handle(
        _codecMeta,
        codec.isAcceptableOrUnknown(data['codec']!, _codecMeta),
      );
    }
    if (data.containsKey('has_embedded_lyrics')) {
      context.handle(
        _hasEmbeddedLyricsMeta,
        hasEmbeddedLyrics.isAcceptableOrUnknown(
          data['has_embedded_lyrics']!,
          _hasEmbeddedLyricsMeta,
        ),
      );
    }
    if (data.containsKey('sidecar_lrc_path')) {
      context.handle(
        _sidecarLrcPathMeta,
        sidecarLrcPath.isAcceptableOrUnknown(
          data['sidecar_lrc_path']!,
          _sidecarLrcPathMeta,
        ),
      );
    }
    if (data.containsKey('folder_cover_path')) {
      context.handle(
        _folderCoverPathMeta,
        folderCoverPath.isAcceptableOrUnknown(
          data['folder_cover_path']!,
          _folderCoverPathMeta,
        ),
      );
    }
    if (data.containsKey('metadata_error')) {
      context.handle(
        _metadataErrorMeta,
        metadataError.isAcceptableOrUnknown(
          data['metadata_error']!,
          _metadataErrorMeta,
        ),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    if (data.containsKey('play_count')) {
      context.handle(
        _playCountMeta,
        playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Track map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Track(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      mtime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mtime'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      albumArtist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_artist'],
      )!,
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_id'],
      ),
      trackNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_no'],
      ),
      discNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disc_no'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      sampleRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_rate'],
      ),
      bitDepth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bit_depth'],
      ),
      bitrate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bitrate'],
      ),
      channels: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channels'],
      ),
      codec: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codec'],
      )!,
      hasEmbeddedLyrics: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_embedded_lyrics'],
      )!,
      sidecarLrcPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sidecar_lrc_path'],
      ),
      folderCoverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_cover_path'],
      ),
      metadataError: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}metadata_error'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
      playCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_count'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_played_at'],
      ),
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class Track extends DataClass implements Insertable<Track> {
  final int id;
  final String path;
  final int size;
  final int mtime;
  final String title;
  final String artist;
  final String albumArtist;
  final String album;
  final int? albumId;
  final int? trackNo;
  final int? discNo;
  final int? year;
  final String genre;
  final int durationMs;
  final int? sampleRate;
  final int? bitDepth;
  final int? bitrate;
  final int? channels;
  final String codec;
  final bool hasEmbeddedLyrics;
  final String? sidecarLrcPath;
  final String? folderCoverPath;
  final bool metadataError;
  final int addedAt;
  final int playCount;
  final int? lastPlayedAt;
  const Track({
    required this.id,
    required this.path,
    required this.size,
    required this.mtime,
    required this.title,
    required this.artist,
    required this.albumArtist,
    required this.album,
    this.albumId,
    this.trackNo,
    this.discNo,
    this.year,
    required this.genre,
    required this.durationMs,
    this.sampleRate,
    this.bitDepth,
    this.bitrate,
    this.channels,
    required this.codec,
    required this.hasEmbeddedLyrics,
    this.sidecarLrcPath,
    this.folderCoverPath,
    required this.metadataError,
    required this.addedAt,
    required this.playCount,
    this.lastPlayedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    map['size'] = Variable<int>(size);
    map['mtime'] = Variable<int>(mtime);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['album_artist'] = Variable<String>(albumArtist);
    map['album'] = Variable<String>(album);
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<int>(albumId);
    }
    if (!nullToAbsent || trackNo != null) {
      map['track_no'] = Variable<int>(trackNo);
    }
    if (!nullToAbsent || discNo != null) {
      map['disc_no'] = Variable<int>(discNo);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    map['genre'] = Variable<String>(genre);
    map['duration_ms'] = Variable<int>(durationMs);
    if (!nullToAbsent || sampleRate != null) {
      map['sample_rate'] = Variable<int>(sampleRate);
    }
    if (!nullToAbsent || bitDepth != null) {
      map['bit_depth'] = Variable<int>(bitDepth);
    }
    if (!nullToAbsent || bitrate != null) {
      map['bitrate'] = Variable<int>(bitrate);
    }
    if (!nullToAbsent || channels != null) {
      map['channels'] = Variable<int>(channels);
    }
    map['codec'] = Variable<String>(codec);
    map['has_embedded_lyrics'] = Variable<bool>(hasEmbeddedLyrics);
    if (!nullToAbsent || sidecarLrcPath != null) {
      map['sidecar_lrc_path'] = Variable<String>(sidecarLrcPath);
    }
    if (!nullToAbsent || folderCoverPath != null) {
      map['folder_cover_path'] = Variable<String>(folderCoverPath);
    }
    map['metadata_error'] = Variable<bool>(metadataError);
    map['added_at'] = Variable<int>(addedAt);
    map['play_count'] = Variable<int>(playCount);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<int>(lastPlayedAt);
    }
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      path: Value(path),
      size: Value(size),
      mtime: Value(mtime),
      title: Value(title),
      artist: Value(artist),
      albumArtist: Value(albumArtist),
      album: Value(album),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      trackNo: trackNo == null && nullToAbsent
          ? const Value.absent()
          : Value(trackNo),
      discNo: discNo == null && nullToAbsent
          ? const Value.absent()
          : Value(discNo),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      genre: Value(genre),
      durationMs: Value(durationMs),
      sampleRate: sampleRate == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleRate),
      bitDepth: bitDepth == null && nullToAbsent
          ? const Value.absent()
          : Value(bitDepth),
      bitrate: bitrate == null && nullToAbsent
          ? const Value.absent()
          : Value(bitrate),
      channels: channels == null && nullToAbsent
          ? const Value.absent()
          : Value(channels),
      codec: Value(codec),
      hasEmbeddedLyrics: Value(hasEmbeddedLyrics),
      sidecarLrcPath: sidecarLrcPath == null && nullToAbsent
          ? const Value.absent()
          : Value(sidecarLrcPath),
      folderCoverPath: folderCoverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(folderCoverPath),
      metadataError: Value(metadataError),
      addedAt: Value(addedAt),
      playCount: Value(playCount),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
    );
  }

  factory Track.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Track(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      size: serializer.fromJson<int>(json['size']),
      mtime: serializer.fromJson<int>(json['mtime']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      albumArtist: serializer.fromJson<String>(json['albumArtist']),
      album: serializer.fromJson<String>(json['album']),
      albumId: serializer.fromJson<int?>(json['albumId']),
      trackNo: serializer.fromJson<int?>(json['trackNo']),
      discNo: serializer.fromJson<int?>(json['discNo']),
      year: serializer.fromJson<int?>(json['year']),
      genre: serializer.fromJson<String>(json['genre']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      sampleRate: serializer.fromJson<int?>(json['sampleRate']),
      bitDepth: serializer.fromJson<int?>(json['bitDepth']),
      bitrate: serializer.fromJson<int?>(json['bitrate']),
      channels: serializer.fromJson<int?>(json['channels']),
      codec: serializer.fromJson<String>(json['codec']),
      hasEmbeddedLyrics: serializer.fromJson<bool>(json['hasEmbeddedLyrics']),
      sidecarLrcPath: serializer.fromJson<String?>(json['sidecarLrcPath']),
      folderCoverPath: serializer.fromJson<String?>(json['folderCoverPath']),
      metadataError: serializer.fromJson<bool>(json['metadataError']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      playCount: serializer.fromJson<int>(json['playCount']),
      lastPlayedAt: serializer.fromJson<int?>(json['lastPlayedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'size': serializer.toJson<int>(size),
      'mtime': serializer.toJson<int>(mtime),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'albumArtist': serializer.toJson<String>(albumArtist),
      'album': serializer.toJson<String>(album),
      'albumId': serializer.toJson<int?>(albumId),
      'trackNo': serializer.toJson<int?>(trackNo),
      'discNo': serializer.toJson<int?>(discNo),
      'year': serializer.toJson<int?>(year),
      'genre': serializer.toJson<String>(genre),
      'durationMs': serializer.toJson<int>(durationMs),
      'sampleRate': serializer.toJson<int?>(sampleRate),
      'bitDepth': serializer.toJson<int?>(bitDepth),
      'bitrate': serializer.toJson<int?>(bitrate),
      'channels': serializer.toJson<int?>(channels),
      'codec': serializer.toJson<String>(codec),
      'hasEmbeddedLyrics': serializer.toJson<bool>(hasEmbeddedLyrics),
      'sidecarLrcPath': serializer.toJson<String?>(sidecarLrcPath),
      'folderCoverPath': serializer.toJson<String?>(folderCoverPath),
      'metadataError': serializer.toJson<bool>(metadataError),
      'addedAt': serializer.toJson<int>(addedAt),
      'playCount': serializer.toJson<int>(playCount),
      'lastPlayedAt': serializer.toJson<int?>(lastPlayedAt),
    };
  }

  Track copyWith({
    int? id,
    String? path,
    int? size,
    int? mtime,
    String? title,
    String? artist,
    String? albumArtist,
    String? album,
    Value<int?> albumId = const Value.absent(),
    Value<int?> trackNo = const Value.absent(),
    Value<int?> discNo = const Value.absent(),
    Value<int?> year = const Value.absent(),
    String? genre,
    int? durationMs,
    Value<int?> sampleRate = const Value.absent(),
    Value<int?> bitDepth = const Value.absent(),
    Value<int?> bitrate = const Value.absent(),
    Value<int?> channels = const Value.absent(),
    String? codec,
    bool? hasEmbeddedLyrics,
    Value<String?> sidecarLrcPath = const Value.absent(),
    Value<String?> folderCoverPath = const Value.absent(),
    bool? metadataError,
    int? addedAt,
    int? playCount,
    Value<int?> lastPlayedAt = const Value.absent(),
  }) => Track(
    id: id ?? this.id,
    path: path ?? this.path,
    size: size ?? this.size,
    mtime: mtime ?? this.mtime,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    albumArtist: albumArtist ?? this.albumArtist,
    album: album ?? this.album,
    albumId: albumId.present ? albumId.value : this.albumId,
    trackNo: trackNo.present ? trackNo.value : this.trackNo,
    discNo: discNo.present ? discNo.value : this.discNo,
    year: year.present ? year.value : this.year,
    genre: genre ?? this.genre,
    durationMs: durationMs ?? this.durationMs,
    sampleRate: sampleRate.present ? sampleRate.value : this.sampleRate,
    bitDepth: bitDepth.present ? bitDepth.value : this.bitDepth,
    bitrate: bitrate.present ? bitrate.value : this.bitrate,
    channels: channels.present ? channels.value : this.channels,
    codec: codec ?? this.codec,
    hasEmbeddedLyrics: hasEmbeddedLyrics ?? this.hasEmbeddedLyrics,
    sidecarLrcPath: sidecarLrcPath.present
        ? sidecarLrcPath.value
        : this.sidecarLrcPath,
    folderCoverPath: folderCoverPath.present
        ? folderCoverPath.value
        : this.folderCoverPath,
    metadataError: metadataError ?? this.metadataError,
    addedAt: addedAt ?? this.addedAt,
    playCount: playCount ?? this.playCount,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
  );
  Track copyWithCompanion(TracksCompanion data) {
    return Track(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      size: data.size.present ? data.size.value : this.size,
      mtime: data.mtime.present ? data.mtime.value : this.mtime,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      albumArtist: data.albumArtist.present
          ? data.albumArtist.value
          : this.albumArtist,
      album: data.album.present ? data.album.value : this.album,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      trackNo: data.trackNo.present ? data.trackNo.value : this.trackNo,
      discNo: data.discNo.present ? data.discNo.value : this.discNo,
      year: data.year.present ? data.year.value : this.year,
      genre: data.genre.present ? data.genre.value : this.genre,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      sampleRate: data.sampleRate.present
          ? data.sampleRate.value
          : this.sampleRate,
      bitDepth: data.bitDepth.present ? data.bitDepth.value : this.bitDepth,
      bitrate: data.bitrate.present ? data.bitrate.value : this.bitrate,
      channels: data.channels.present ? data.channels.value : this.channels,
      codec: data.codec.present ? data.codec.value : this.codec,
      hasEmbeddedLyrics: data.hasEmbeddedLyrics.present
          ? data.hasEmbeddedLyrics.value
          : this.hasEmbeddedLyrics,
      sidecarLrcPath: data.sidecarLrcPath.present
          ? data.sidecarLrcPath.value
          : this.sidecarLrcPath,
      folderCoverPath: data.folderCoverPath.present
          ? data.folderCoverPath.value
          : this.folderCoverPath,
      metadataError: data.metadataError.present
          ? data.metadataError.value
          : this.metadataError,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Track(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('size: $size, ')
          ..write('mtime: $mtime, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('album: $album, ')
          ..write('albumId: $albumId, ')
          ..write('trackNo: $trackNo, ')
          ..write('discNo: $discNo, ')
          ..write('year: $year, ')
          ..write('genre: $genre, ')
          ..write('durationMs: $durationMs, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('bitDepth: $bitDepth, ')
          ..write('bitrate: $bitrate, ')
          ..write('channels: $channels, ')
          ..write('codec: $codec, ')
          ..write('hasEmbeddedLyrics: $hasEmbeddedLyrics, ')
          ..write('sidecarLrcPath: $sidecarLrcPath, ')
          ..write('folderCoverPath: $folderCoverPath, ')
          ..write('metadataError: $metadataError, ')
          ..write('addedAt: $addedAt, ')
          ..write('playCount: $playCount, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    path,
    size,
    mtime,
    title,
    artist,
    albumArtist,
    album,
    albumId,
    trackNo,
    discNo,
    year,
    genre,
    durationMs,
    sampleRate,
    bitDepth,
    bitrate,
    channels,
    codec,
    hasEmbeddedLyrics,
    sidecarLrcPath,
    folderCoverPath,
    metadataError,
    addedAt,
    playCount,
    lastPlayedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Track &&
          other.id == this.id &&
          other.path == this.path &&
          other.size == this.size &&
          other.mtime == this.mtime &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.albumArtist == this.albumArtist &&
          other.album == this.album &&
          other.albumId == this.albumId &&
          other.trackNo == this.trackNo &&
          other.discNo == this.discNo &&
          other.year == this.year &&
          other.genre == this.genre &&
          other.durationMs == this.durationMs &&
          other.sampleRate == this.sampleRate &&
          other.bitDepth == this.bitDepth &&
          other.bitrate == this.bitrate &&
          other.channels == this.channels &&
          other.codec == this.codec &&
          other.hasEmbeddedLyrics == this.hasEmbeddedLyrics &&
          other.sidecarLrcPath == this.sidecarLrcPath &&
          other.folderCoverPath == this.folderCoverPath &&
          other.metadataError == this.metadataError &&
          other.addedAt == this.addedAt &&
          other.playCount == this.playCount &&
          other.lastPlayedAt == this.lastPlayedAt);
}

class TracksCompanion extends UpdateCompanion<Track> {
  final Value<int> id;
  final Value<String> path;
  final Value<int> size;
  final Value<int> mtime;
  final Value<String> title;
  final Value<String> artist;
  final Value<String> albumArtist;
  final Value<String> album;
  final Value<int?> albumId;
  final Value<int?> trackNo;
  final Value<int?> discNo;
  final Value<int?> year;
  final Value<String> genre;
  final Value<int> durationMs;
  final Value<int?> sampleRate;
  final Value<int?> bitDepth;
  final Value<int?> bitrate;
  final Value<int?> channels;
  final Value<String> codec;
  final Value<bool> hasEmbeddedLyrics;
  final Value<String?> sidecarLrcPath;
  final Value<String?> folderCoverPath;
  final Value<bool> metadataError;
  final Value<int> addedAt;
  final Value<int> playCount;
  final Value<int?> lastPlayedAt;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.size = const Value.absent(),
    this.mtime = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.album = const Value.absent(),
    this.albumId = const Value.absent(),
    this.trackNo = const Value.absent(),
    this.discNo = const Value.absent(),
    this.year = const Value.absent(),
    this.genre = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sampleRate = const Value.absent(),
    this.bitDepth = const Value.absent(),
    this.bitrate = const Value.absent(),
    this.channels = const Value.absent(),
    this.codec = const Value.absent(),
    this.hasEmbeddedLyrics = const Value.absent(),
    this.sidecarLrcPath = const Value.absent(),
    this.folderCoverPath = const Value.absent(),
    this.metadataError = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.playCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
  });
  TracksCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    this.size = const Value.absent(),
    this.mtime = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.album = const Value.absent(),
    this.albumId = const Value.absent(),
    this.trackNo = const Value.absent(),
    this.discNo = const Value.absent(),
    this.year = const Value.absent(),
    this.genre = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sampleRate = const Value.absent(),
    this.bitDepth = const Value.absent(),
    this.bitrate = const Value.absent(),
    this.channels = const Value.absent(),
    this.codec = const Value.absent(),
    this.hasEmbeddedLyrics = const Value.absent(),
    this.sidecarLrcPath = const Value.absent(),
    this.folderCoverPath = const Value.absent(),
    this.metadataError = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.playCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
  }) : path = Value(path);
  static Insertable<Track> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<int>? size,
    Expression<int>? mtime,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? albumArtist,
    Expression<String>? album,
    Expression<int>? albumId,
    Expression<int>? trackNo,
    Expression<int>? discNo,
    Expression<int>? year,
    Expression<String>? genre,
    Expression<int>? durationMs,
    Expression<int>? sampleRate,
    Expression<int>? bitDepth,
    Expression<int>? bitrate,
    Expression<int>? channels,
    Expression<String>? codec,
    Expression<bool>? hasEmbeddedLyrics,
    Expression<String>? sidecarLrcPath,
    Expression<String>? folderCoverPath,
    Expression<bool>? metadataError,
    Expression<int>? addedAt,
    Expression<int>? playCount,
    Expression<int>? lastPlayedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (size != null) 'size': size,
      if (mtime != null) 'mtime': mtime,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (albumArtist != null) 'album_artist': albumArtist,
      if (album != null) 'album': album,
      if (albumId != null) 'album_id': albumId,
      if (trackNo != null) 'track_no': trackNo,
      if (discNo != null) 'disc_no': discNo,
      if (year != null) 'year': year,
      if (genre != null) 'genre': genre,
      if (durationMs != null) 'duration_ms': durationMs,
      if (sampleRate != null) 'sample_rate': sampleRate,
      if (bitDepth != null) 'bit_depth': bitDepth,
      if (bitrate != null) 'bitrate': bitrate,
      if (channels != null) 'channels': channels,
      if (codec != null) 'codec': codec,
      if (hasEmbeddedLyrics != null) 'has_embedded_lyrics': hasEmbeddedLyrics,
      if (sidecarLrcPath != null) 'sidecar_lrc_path': sidecarLrcPath,
      if (folderCoverPath != null) 'folder_cover_path': folderCoverPath,
      if (metadataError != null) 'metadata_error': metadataError,
      if (addedAt != null) 'added_at': addedAt,
      if (playCount != null) 'play_count': playCount,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
    });
  }

  TracksCompanion copyWith({
    Value<int>? id,
    Value<String>? path,
    Value<int>? size,
    Value<int>? mtime,
    Value<String>? title,
    Value<String>? artist,
    Value<String>? albumArtist,
    Value<String>? album,
    Value<int?>? albumId,
    Value<int?>? trackNo,
    Value<int?>? discNo,
    Value<int?>? year,
    Value<String>? genre,
    Value<int>? durationMs,
    Value<int?>? sampleRate,
    Value<int?>? bitDepth,
    Value<int?>? bitrate,
    Value<int?>? channels,
    Value<String>? codec,
    Value<bool>? hasEmbeddedLyrics,
    Value<String?>? sidecarLrcPath,
    Value<String?>? folderCoverPath,
    Value<bool>? metadataError,
    Value<int>? addedAt,
    Value<int>? playCount,
    Value<int?>? lastPlayedAt,
  }) {
    return TracksCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      size: size ?? this.size,
      mtime: mtime ?? this.mtime,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArtist: albumArtist ?? this.albumArtist,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      trackNo: trackNo ?? this.trackNo,
      discNo: discNo ?? this.discNo,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      durationMs: durationMs ?? this.durationMs,
      sampleRate: sampleRate ?? this.sampleRate,
      bitDepth: bitDepth ?? this.bitDepth,
      bitrate: bitrate ?? this.bitrate,
      channels: channels ?? this.channels,
      codec: codec ?? this.codec,
      hasEmbeddedLyrics: hasEmbeddedLyrics ?? this.hasEmbeddedLyrics,
      sidecarLrcPath: sidecarLrcPath ?? this.sidecarLrcPath,
      folderCoverPath: folderCoverPath ?? this.folderCoverPath,
      metadataError: metadataError ?? this.metadataError,
      addedAt: addedAt ?? this.addedAt,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (mtime.present) {
      map['mtime'] = Variable<int>(mtime.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (albumArtist.present) {
      map['album_artist'] = Variable<String>(albumArtist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<int>(albumId.value);
    }
    if (trackNo.present) {
      map['track_no'] = Variable<int>(trackNo.value);
    }
    if (discNo.present) {
      map['disc_no'] = Variable<int>(discNo.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (sampleRate.present) {
      map['sample_rate'] = Variable<int>(sampleRate.value);
    }
    if (bitDepth.present) {
      map['bit_depth'] = Variable<int>(bitDepth.value);
    }
    if (bitrate.present) {
      map['bitrate'] = Variable<int>(bitrate.value);
    }
    if (channels.present) {
      map['channels'] = Variable<int>(channels.value);
    }
    if (codec.present) {
      map['codec'] = Variable<String>(codec.value);
    }
    if (hasEmbeddedLyrics.present) {
      map['has_embedded_lyrics'] = Variable<bool>(hasEmbeddedLyrics.value);
    }
    if (sidecarLrcPath.present) {
      map['sidecar_lrc_path'] = Variable<String>(sidecarLrcPath.value);
    }
    if (folderCoverPath.present) {
      map['folder_cover_path'] = Variable<String>(folderCoverPath.value);
    }
    if (metadataError.present) {
      map['metadata_error'] = Variable<bool>(metadataError.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<int>(lastPlayedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('size: $size, ')
          ..write('mtime: $mtime, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('album: $album, ')
          ..write('albumId: $albumId, ')
          ..write('trackNo: $trackNo, ')
          ..write('discNo: $discNo, ')
          ..write('year: $year, ')
          ..write('genre: $genre, ')
          ..write('durationMs: $durationMs, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('bitDepth: $bitDepth, ')
          ..write('bitrate: $bitrate, ')
          ..write('channels: $channels, ')
          ..write('codec: $codec, ')
          ..write('hasEmbeddedLyrics: $hasEmbeddedLyrics, ')
          ..write('sidecarLrcPath: $sidecarLrcPath, ')
          ..write('folderCoverPath: $folderCoverPath, ')
          ..write('metadataError: $metadataError, ')
          ..write('addedAt: $addedAt, ')
          ..write('playCount: $playCount, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }
}

class $ArtistsTable extends Artists with TableInfo<$ArtistsTable, Artist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameKeyMeta = const VerificationMeta(
    'nameKey',
  );
  @override
  late final GeneratedColumn<String> nameKey = GeneratedColumn<String>(
    'name_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nameKey, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Artist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name_key')) {
      context.handle(
        _nameKeyMeta,
        nameKey.isAcceptableOrUnknown(data['name_key']!, _nameKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_nameKeyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Artist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Artist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $ArtistsTable createAlias(String alias) {
    return $ArtistsTable(attachedDatabase, alias);
  }
}

class Artist extends DataClass implements Insertable<Artist> {
  final int id;
  final String nameKey;
  final String name;
  const Artist({required this.id, required this.nameKey, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name_key'] = Variable<String>(nameKey);
    map['name'] = Variable<String>(name);
    return map;
  }

  ArtistsCompanion toCompanion(bool nullToAbsent) {
    return ArtistsCompanion(
      id: Value(id),
      nameKey: Value(nameKey),
      name: Value(name),
    );
  }

  factory Artist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Artist(
      id: serializer.fromJson<int>(json['id']),
      nameKey: serializer.fromJson<String>(json['nameKey']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nameKey': serializer.toJson<String>(nameKey),
      'name': serializer.toJson<String>(name),
    };
  }

  Artist copyWith({int? id, String? nameKey, String? name}) => Artist(
    id: id ?? this.id,
    nameKey: nameKey ?? this.nameKey,
    name: name ?? this.name,
  );
  Artist copyWithCompanion(ArtistsCompanion data) {
    return Artist(
      id: data.id.present ? data.id.value : this.id,
      nameKey: data.nameKey.present ? data.nameKey.value : this.nameKey,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Artist(')
          ..write('id: $id, ')
          ..write('nameKey: $nameKey, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nameKey, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Artist &&
          other.id == this.id &&
          other.nameKey == this.nameKey &&
          other.name == this.name);
}

class ArtistsCompanion extends UpdateCompanion<Artist> {
  final Value<int> id;
  final Value<String> nameKey;
  final Value<String> name;
  const ArtistsCompanion({
    this.id = const Value.absent(),
    this.nameKey = const Value.absent(),
    this.name = const Value.absent(),
  });
  ArtistsCompanion.insert({
    this.id = const Value.absent(),
    required String nameKey,
    required String name,
  }) : nameKey = Value(nameKey),
       name = Value(name);
  static Insertable<Artist> custom({
    Expression<int>? id,
    Expression<String>? nameKey,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameKey != null) 'name_key': nameKey,
      if (name != null) 'name': name,
    });
  }

  ArtistsCompanion copyWith({
    Value<int>? id,
    Value<String>? nameKey,
    Value<String>? name,
  }) {
    return ArtistsCompanion(
      id: id ?? this.id,
      nameKey: nameKey ?? this.nameKey,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nameKey.present) {
      map['name_key'] = Variable<String>(nameKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtistsCompanion(')
          ..write('id: $id, ')
          ..write('nameKey: $nameKey, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $TrackArtistsTable extends TrackArtists
    with TableInfo<$TrackArtistsTable, TrackArtist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackArtistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<int> artistId = GeneratedColumn<int>(
    'artist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES artists (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [trackId, artistId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_artists';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackArtist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_artistIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId, artistId};
  @override
  TrackArtist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackArtist(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}artist_id'],
      )!,
    );
  }

  @override
  $TrackArtistsTable createAlias(String alias) {
    return $TrackArtistsTable(attachedDatabase, alias);
  }
}

class TrackArtist extends DataClass implements Insertable<TrackArtist> {
  final int trackId;
  final int artistId;
  const TrackArtist({required this.trackId, required this.artistId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<int>(trackId);
    map['artist_id'] = Variable<int>(artistId);
    return map;
  }

  TrackArtistsCompanion toCompanion(bool nullToAbsent) {
    return TrackArtistsCompanion(
      trackId: Value(trackId),
      artistId: Value(artistId),
    );
  }

  factory TrackArtist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackArtist(
      trackId: serializer.fromJson<int>(json['trackId']),
      artistId: serializer.fromJson<int>(json['artistId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<int>(trackId),
      'artistId': serializer.toJson<int>(artistId),
    };
  }

  TrackArtist copyWith({int? trackId, int? artistId}) => TrackArtist(
    trackId: trackId ?? this.trackId,
    artistId: artistId ?? this.artistId,
  );
  TrackArtist copyWithCompanion(TrackArtistsCompanion data) {
    return TrackArtist(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackArtist(')
          ..write('trackId: $trackId, ')
          ..write('artistId: $artistId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackId, artistId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackArtist &&
          other.trackId == this.trackId &&
          other.artistId == this.artistId);
}

class TrackArtistsCompanion extends UpdateCompanion<TrackArtist> {
  final Value<int> trackId;
  final Value<int> artistId;
  final Value<int> rowid;
  const TrackArtistsCompanion({
    this.trackId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackArtistsCompanion.insert({
    required int trackId,
    required int artistId,
    this.rowid = const Value.absent(),
  }) : trackId = Value(trackId),
       artistId = Value(artistId);
  static Insertable<TrackArtist> custom({
    Expression<int>? trackId,
    Expression<int>? artistId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (artistId != null) 'artist_id': artistId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackArtistsCompanion copyWith({
    Value<int>? trackId,
    Value<int>? artistId,
    Value<int>? rowid,
  }) {
    return TrackArtistsCompanion(
      trackId: trackId ?? this.trackId,
      artistId: artistId ?? this.artistId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<int>(artistId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackArtistsCompanion(')
          ..write('trackId: $trackId, ')
          ..write('artistId: $artistId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LibraryRootsTable extends LibraryRoots
    with TableInfo<$LibraryRootsTable, LibraryRoot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryRootsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _excludedMeta = const VerificationMeta(
    'excluded',
  );
  @override
  late final GeneratedColumn<bool> excluded = GeneratedColumn<bool>(
    'excluded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("excluded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, path, excluded];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_roots';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryRoot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('excluded')) {
      context.handle(
        _excludedMeta,
        excluded.isAcceptableOrUnknown(data['excluded']!, _excludedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibraryRoot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryRoot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      excluded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}excluded'],
      )!,
    );
  }

  @override
  $LibraryRootsTable createAlias(String alias) {
    return $LibraryRootsTable(attachedDatabase, alias);
  }
}

class LibraryRoot extends DataClass implements Insertable<LibraryRoot> {
  final int id;
  final String path;
  final bool excluded;
  const LibraryRoot({
    required this.id,
    required this.path,
    required this.excluded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    map['excluded'] = Variable<bool>(excluded);
    return map;
  }

  LibraryRootsCompanion toCompanion(bool nullToAbsent) {
    return LibraryRootsCompanion(
      id: Value(id),
      path: Value(path),
      excluded: Value(excluded),
    );
  }

  factory LibraryRoot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryRoot(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      excluded: serializer.fromJson<bool>(json['excluded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'excluded': serializer.toJson<bool>(excluded),
    };
  }

  LibraryRoot copyWith({int? id, String? path, bool? excluded}) => LibraryRoot(
    id: id ?? this.id,
    path: path ?? this.path,
    excluded: excluded ?? this.excluded,
  );
  LibraryRoot copyWithCompanion(LibraryRootsCompanion data) {
    return LibraryRoot(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      excluded: data.excluded.present ? data.excluded.value : this.excluded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryRoot(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('excluded: $excluded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, path, excluded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryRoot &&
          other.id == this.id &&
          other.path == this.path &&
          other.excluded == this.excluded);
}

class LibraryRootsCompanion extends UpdateCompanion<LibraryRoot> {
  final Value<int> id;
  final Value<String> path;
  final Value<bool> excluded;
  const LibraryRootsCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.excluded = const Value.absent(),
  });
  LibraryRootsCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    this.excluded = const Value.absent(),
  }) : path = Value(path);
  static Insertable<LibraryRoot> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<bool>? excluded,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (excluded != null) 'excluded': excluded,
    });
  }

  LibraryRootsCompanion copyWith({
    Value<int>? id,
    Value<String>? path,
    Value<bool>? excluded,
  }) {
    return LibraryRootsCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      excluded: excluded ?? this.excluded,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (excluded.present) {
      map['excluded'] = Variable<bool>(excluded.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryRootsCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('excluded: $excluded')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, Playlist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Playlist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Playlist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Playlist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class Playlist extends DataClass implements Insertable<Playlist> {
  final int id;
  final String name;
  final int createdAt;
  final int updatedAt;
  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Playlist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Playlist(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Playlist copyWith({int? id, String? name, int? createdAt, int? updatedAt}) =>
      Playlist(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Playlist copyWithCompanion(PlaylistsCompanion data) {
    return Playlist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Playlist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlaylistsCompanion extends UpdateCompanion<Playlist> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int createdAt,
    required int updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Playlist> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PlaylistsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PlaylistItemsTable extends PlaylistItems
    with TableInfo<$PlaylistItemsTable, PlaylistItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [playlistId, position, trackId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, position};
  @override
  PlaylistItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistItem(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playlist_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
    );
  }

  @override
  $PlaylistItemsTable createAlias(String alias) {
    return $PlaylistItemsTable(attachedDatabase, alias);
  }
}

class PlaylistItem extends DataClass implements Insertable<PlaylistItem> {
  final int playlistId;
  final int position;
  final int trackId;
  const PlaylistItem({
    required this.playlistId,
    required this.position,
    required this.trackId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<int>(playlistId);
    map['position'] = Variable<int>(position);
    map['track_id'] = Variable<int>(trackId);
    return map;
  }

  PlaylistItemsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistItemsCompanion(
      playlistId: Value(playlistId),
      position: Value(position),
      trackId: Value(trackId),
    );
  }

  factory PlaylistItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistItem(
      playlistId: serializer.fromJson<int>(json['playlistId']),
      position: serializer.fromJson<int>(json['position']),
      trackId: serializer.fromJson<int>(json['trackId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<int>(playlistId),
      'position': serializer.toJson<int>(position),
      'trackId': serializer.toJson<int>(trackId),
    };
  }

  PlaylistItem copyWith({int? playlistId, int? position, int? trackId}) =>
      PlaylistItem(
        playlistId: playlistId ?? this.playlistId,
        position: position ?? this.position,
        trackId: trackId ?? this.trackId,
      );
  PlaylistItem copyWithCompanion(PlaylistItemsCompanion data) {
    return PlaylistItem(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      position: data.position.present ? data.position.value : this.position,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistItem(')
          ..write('playlistId: $playlistId, ')
          ..write('position: $position, ')
          ..write('trackId: $trackId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, position, trackId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistItem &&
          other.playlistId == this.playlistId &&
          other.position == this.position &&
          other.trackId == this.trackId);
}

class PlaylistItemsCompanion extends UpdateCompanion<PlaylistItem> {
  final Value<int> playlistId;
  final Value<int> position;
  final Value<int> trackId;
  final Value<int> rowid;
  const PlaylistItemsCompanion({
    this.playlistId = const Value.absent(),
    this.position = const Value.absent(),
    this.trackId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistItemsCompanion.insert({
    required int playlistId,
    required int position,
    required int trackId,
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       position = Value(position),
       trackId = Value(trackId);
  static Insertable<PlaylistItem> custom({
    Expression<int>? playlistId,
    Expression<int>? position,
    Expression<int>? trackId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (position != null) 'position': position,
      if (trackId != null) 'track_id': trackId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistItemsCompanion copyWith({
    Value<int>? playlistId,
    Value<int>? position,
    Value<int>? trackId,
    Value<int>? rowid,
  }) {
    return PlaylistItemsCompanion(
      playlistId: playlistId ?? this.playlistId,
      position: position ?? this.position,
      trackId: trackId ?? this.trackId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistItemsCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('position: $position, ')
          ..write('trackId: $trackId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EqPresetsTable extends EqPresets
    with TableInfo<$EqPresetsTable, EqPreset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EqPresetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _builtinMeta = const VerificationMeta(
    'builtin',
  );
  @override
  late final GeneratedColumn<bool> builtin = GeneratedColumn<bool>(
    'builtin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("builtin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _gainsJsonMeta = const VerificationMeta(
    'gainsJson',
  );
  @override
  late final GeneratedColumn<String> gainsJson = GeneratedColumn<String>(
    'gains_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _preampMeta = const VerificationMeta('preamp');
  @override
  late final GeneratedColumn<double> preamp = GeneratedColumn<double>(
    'preamp',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, builtin, gainsJson, preamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'eq_presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<EqPreset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('builtin')) {
      context.handle(
        _builtinMeta,
        builtin.isAcceptableOrUnknown(data['builtin']!, _builtinMeta),
      );
    }
    if (data.containsKey('gains_json')) {
      context.handle(
        _gainsJsonMeta,
        gainsJson.isAcceptableOrUnknown(data['gains_json']!, _gainsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_gainsJsonMeta);
    }
    if (data.containsKey('preamp')) {
      context.handle(
        _preampMeta,
        preamp.isAcceptableOrUnknown(data['preamp']!, _preampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EqPreset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EqPreset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      builtin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}builtin'],
      )!,
      gainsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gains_json'],
      )!,
      preamp: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}preamp'],
      )!,
    );
  }

  @override
  $EqPresetsTable createAlias(String alias) {
    return $EqPresetsTable(attachedDatabase, alias);
  }
}

class EqPreset extends DataClass implements Insertable<EqPreset> {
  final int id;
  final String name;
  final bool builtin;
  final String gainsJson;
  final double preamp;
  const EqPreset({
    required this.id,
    required this.name,
    required this.builtin,
    required this.gainsJson,
    required this.preamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['builtin'] = Variable<bool>(builtin);
    map['gains_json'] = Variable<String>(gainsJson);
    map['preamp'] = Variable<double>(preamp);
    return map;
  }

  EqPresetsCompanion toCompanion(bool nullToAbsent) {
    return EqPresetsCompanion(
      id: Value(id),
      name: Value(name),
      builtin: Value(builtin),
      gainsJson: Value(gainsJson),
      preamp: Value(preamp),
    );
  }

  factory EqPreset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EqPreset(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      builtin: serializer.fromJson<bool>(json['builtin']),
      gainsJson: serializer.fromJson<String>(json['gainsJson']),
      preamp: serializer.fromJson<double>(json['preamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'builtin': serializer.toJson<bool>(builtin),
      'gainsJson': serializer.toJson<String>(gainsJson),
      'preamp': serializer.toJson<double>(preamp),
    };
  }

  EqPreset copyWith({
    int? id,
    String? name,
    bool? builtin,
    String? gainsJson,
    double? preamp,
  }) => EqPreset(
    id: id ?? this.id,
    name: name ?? this.name,
    builtin: builtin ?? this.builtin,
    gainsJson: gainsJson ?? this.gainsJson,
    preamp: preamp ?? this.preamp,
  );
  EqPreset copyWithCompanion(EqPresetsCompanion data) {
    return EqPreset(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      builtin: data.builtin.present ? data.builtin.value : this.builtin,
      gainsJson: data.gainsJson.present ? data.gainsJson.value : this.gainsJson,
      preamp: data.preamp.present ? data.preamp.value : this.preamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EqPreset(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('builtin: $builtin, ')
          ..write('gainsJson: $gainsJson, ')
          ..write('preamp: $preamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, builtin, gainsJson, preamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EqPreset &&
          other.id == this.id &&
          other.name == this.name &&
          other.builtin == this.builtin &&
          other.gainsJson == this.gainsJson &&
          other.preamp == this.preamp);
}

class EqPresetsCompanion extends UpdateCompanion<EqPreset> {
  final Value<int> id;
  final Value<String> name;
  final Value<bool> builtin;
  final Value<String> gainsJson;
  final Value<double> preamp;
  const EqPresetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.builtin = const Value.absent(),
    this.gainsJson = const Value.absent(),
    this.preamp = const Value.absent(),
  });
  EqPresetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.builtin = const Value.absent(),
    required String gainsJson,
    this.preamp = const Value.absent(),
  }) : name = Value(name),
       gainsJson = Value(gainsJson);
  static Insertable<EqPreset> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<bool>? builtin,
    Expression<String>? gainsJson,
    Expression<double>? preamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (builtin != null) 'builtin': builtin,
      if (gainsJson != null) 'gains_json': gainsJson,
      if (preamp != null) 'preamp': preamp,
    });
  }

  EqPresetsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<bool>? builtin,
    Value<String>? gainsJson,
    Value<double>? preamp,
  }) {
    return EqPresetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      builtin: builtin ?? this.builtin,
      gainsJson: gainsJson ?? this.gainsJson,
      preamp: preamp ?? this.preamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (builtin.present) {
      map['builtin'] = Variable<bool>(builtin.value);
    }
    if (gainsJson.present) {
      map['gains_json'] = Variable<String>(gainsJson.value);
    }
    if (preamp.present) {
      map['preamp'] = Variable<double>(preamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EqPresetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('builtin: $builtin, ')
          ..write('gainsJson: $gainsJson, ')
          ..write('preamp: $preamp')
          ..write(')'))
        .toString();
  }
}

class $PlaybackStateTable extends PlaybackState
    with TableInfo<$PlaybackStateTable, PlaybackStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _queueJsonMeta = const VerificationMeta(
    'queueJson',
  );
  @override
  late final GeneratedColumn<String> queueJson = GeneratedColumn<String>(
    'queue_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _shuffledJsonMeta = const VerificationMeta(
    'shuffledJson',
  );
  @override
  late final GeneratedColumn<String> shuffledJson = GeneratedColumn<String>(
    'shuffled_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _currentIndexMeta = const VerificationMeta(
    'currentIndex',
  );
  @override
  late final GeneratedColumn<int> currentIndex = GeneratedColumn<int>(
    'current_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _loopModeMeta = const VerificationMeta(
    'loopMode',
  );
  @override
  late final GeneratedColumn<int> loopMode = GeneratedColumn<int>(
    'loop_mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _shuffleMeta = const VerificationMeta(
    'shuffle',
  );
  @override
  late final GeneratedColumn<bool> shuffle = GeneratedColumn<bool>(
    'shuffle',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("shuffle" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    queueJson,
    shuffledJson,
    currentIndex,
    positionMs,
    loopMode,
    shuffle,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('queue_json')) {
      context.handle(
        _queueJsonMeta,
        queueJson.isAcceptableOrUnknown(data['queue_json']!, _queueJsonMeta),
      );
    }
    if (data.containsKey('shuffled_json')) {
      context.handle(
        _shuffledJsonMeta,
        shuffledJson.isAcceptableOrUnknown(
          data['shuffled_json']!,
          _shuffledJsonMeta,
        ),
      );
    }
    if (data.containsKey('current_index')) {
      context.handle(
        _currentIndexMeta,
        currentIndex.isAcceptableOrUnknown(
          data['current_index']!,
          _currentIndexMeta,
        ),
      );
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('loop_mode')) {
      context.handle(
        _loopModeMeta,
        loopMode.isAcceptableOrUnknown(data['loop_mode']!, _loopModeMeta),
      );
    }
    if (data.containsKey('shuffle')) {
      context.handle(
        _shuffleMeta,
        shuffle.isAcceptableOrUnknown(data['shuffle']!, _shuffleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaybackStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      queueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}queue_json'],
      )!,
      shuffledJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shuffled_json'],
      )!,
      currentIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_index'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      loopMode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}loop_mode'],
      )!,
      shuffle: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}shuffle'],
      )!,
    );
  }

  @override
  $PlaybackStateTable createAlias(String alias) {
    return $PlaybackStateTable(attachedDatabase, alias);
  }
}

class PlaybackStateData extends DataClass
    implements Insertable<PlaybackStateData> {
  final int id;
  final String queueJson;
  final String shuffledJson;
  final int currentIndex;
  final int positionMs;
  final int loopMode;
  final bool shuffle;
  const PlaybackStateData({
    required this.id,
    required this.queueJson,
    required this.shuffledJson,
    required this.currentIndex,
    required this.positionMs,
    required this.loopMode,
    required this.shuffle,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['queue_json'] = Variable<String>(queueJson);
    map['shuffled_json'] = Variable<String>(shuffledJson);
    map['current_index'] = Variable<int>(currentIndex);
    map['position_ms'] = Variable<int>(positionMs);
    map['loop_mode'] = Variable<int>(loopMode);
    map['shuffle'] = Variable<bool>(shuffle);
    return map;
  }

  PlaybackStateCompanion toCompanion(bool nullToAbsent) {
    return PlaybackStateCompanion(
      id: Value(id),
      queueJson: Value(queueJson),
      shuffledJson: Value(shuffledJson),
      currentIndex: Value(currentIndex),
      positionMs: Value(positionMs),
      loopMode: Value(loopMode),
      shuffle: Value(shuffle),
    );
  }

  factory PlaybackStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackStateData(
      id: serializer.fromJson<int>(json['id']),
      queueJson: serializer.fromJson<String>(json['queueJson']),
      shuffledJson: serializer.fromJson<String>(json['shuffledJson']),
      currentIndex: serializer.fromJson<int>(json['currentIndex']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      loopMode: serializer.fromJson<int>(json['loopMode']),
      shuffle: serializer.fromJson<bool>(json['shuffle']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'queueJson': serializer.toJson<String>(queueJson),
      'shuffledJson': serializer.toJson<String>(shuffledJson),
      'currentIndex': serializer.toJson<int>(currentIndex),
      'positionMs': serializer.toJson<int>(positionMs),
      'loopMode': serializer.toJson<int>(loopMode),
      'shuffle': serializer.toJson<bool>(shuffle),
    };
  }

  PlaybackStateData copyWith({
    int? id,
    String? queueJson,
    String? shuffledJson,
    int? currentIndex,
    int? positionMs,
    int? loopMode,
    bool? shuffle,
  }) => PlaybackStateData(
    id: id ?? this.id,
    queueJson: queueJson ?? this.queueJson,
    shuffledJson: shuffledJson ?? this.shuffledJson,
    currentIndex: currentIndex ?? this.currentIndex,
    positionMs: positionMs ?? this.positionMs,
    loopMode: loopMode ?? this.loopMode,
    shuffle: shuffle ?? this.shuffle,
  );
  PlaybackStateData copyWithCompanion(PlaybackStateCompanion data) {
    return PlaybackStateData(
      id: data.id.present ? data.id.value : this.id,
      queueJson: data.queueJson.present ? data.queueJson.value : this.queueJson,
      shuffledJson: data.shuffledJson.present
          ? data.shuffledJson.value
          : this.shuffledJson,
      currentIndex: data.currentIndex.present
          ? data.currentIndex.value
          : this.currentIndex,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      loopMode: data.loopMode.present ? data.loopMode.value : this.loopMode,
      shuffle: data.shuffle.present ? data.shuffle.value : this.shuffle,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackStateData(')
          ..write('id: $id, ')
          ..write('queueJson: $queueJson, ')
          ..write('shuffledJson: $shuffledJson, ')
          ..write('currentIndex: $currentIndex, ')
          ..write('positionMs: $positionMs, ')
          ..write('loopMode: $loopMode, ')
          ..write('shuffle: $shuffle')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    queueJson,
    shuffledJson,
    currentIndex,
    positionMs,
    loopMode,
    shuffle,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackStateData &&
          other.id == this.id &&
          other.queueJson == this.queueJson &&
          other.shuffledJson == this.shuffledJson &&
          other.currentIndex == this.currentIndex &&
          other.positionMs == this.positionMs &&
          other.loopMode == this.loopMode &&
          other.shuffle == this.shuffle);
}

class PlaybackStateCompanion extends UpdateCompanion<PlaybackStateData> {
  final Value<int> id;
  final Value<String> queueJson;
  final Value<String> shuffledJson;
  final Value<int> currentIndex;
  final Value<int> positionMs;
  final Value<int> loopMode;
  final Value<bool> shuffle;
  const PlaybackStateCompanion({
    this.id = const Value.absent(),
    this.queueJson = const Value.absent(),
    this.shuffledJson = const Value.absent(),
    this.currentIndex = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.loopMode = const Value.absent(),
    this.shuffle = const Value.absent(),
  });
  PlaybackStateCompanion.insert({
    this.id = const Value.absent(),
    this.queueJson = const Value.absent(),
    this.shuffledJson = const Value.absent(),
    this.currentIndex = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.loopMode = const Value.absent(),
    this.shuffle = const Value.absent(),
  });
  static Insertable<PlaybackStateData> custom({
    Expression<int>? id,
    Expression<String>? queueJson,
    Expression<String>? shuffledJson,
    Expression<int>? currentIndex,
    Expression<int>? positionMs,
    Expression<int>? loopMode,
    Expression<bool>? shuffle,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (queueJson != null) 'queue_json': queueJson,
      if (shuffledJson != null) 'shuffled_json': shuffledJson,
      if (currentIndex != null) 'current_index': currentIndex,
      if (positionMs != null) 'position_ms': positionMs,
      if (loopMode != null) 'loop_mode': loopMode,
      if (shuffle != null) 'shuffle': shuffle,
    });
  }

  PlaybackStateCompanion copyWith({
    Value<int>? id,
    Value<String>? queueJson,
    Value<String>? shuffledJson,
    Value<int>? currentIndex,
    Value<int>? positionMs,
    Value<int>? loopMode,
    Value<bool>? shuffle,
  }) {
    return PlaybackStateCompanion(
      id: id ?? this.id,
      queueJson: queueJson ?? this.queueJson,
      shuffledJson: shuffledJson ?? this.shuffledJson,
      currentIndex: currentIndex ?? this.currentIndex,
      positionMs: positionMs ?? this.positionMs,
      loopMode: loopMode ?? this.loopMode,
      shuffle: shuffle ?? this.shuffle,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (queueJson.present) {
      map['queue_json'] = Variable<String>(queueJson.value);
    }
    if (shuffledJson.present) {
      map['shuffled_json'] = Variable<String>(shuffledJson.value);
    }
    if (currentIndex.present) {
      map['current_index'] = Variable<int>(currentIndex.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (loopMode.present) {
      map['loop_mode'] = Variable<int>(loopMode.value);
    }
    if (shuffle.present) {
      map['shuffle'] = Variable<bool>(shuffle.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackStateCompanion(')
          ..write('id: $id, ')
          ..write('queueJson: $queueJson, ')
          ..write('shuffledJson: $shuffledJson, ')
          ..write('currentIndex: $currentIndex, ')
          ..write('positionMs: $positionMs, ')
          ..write('loopMode: $loopMode, ')
          ..write('shuffle: $shuffle')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScanErrorsTable extends ScanErrors
    with TableInfo<$ScanErrorsTable, ScanError> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanErrorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<int> at = GeneratedColumn<int>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [path, message, at];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_errors';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanError> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path};
  @override
  ScanError map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanError(
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $ScanErrorsTable createAlias(String alias) {
    return $ScanErrorsTable(attachedDatabase, alias);
  }
}

class ScanError extends DataClass implements Insertable<ScanError> {
  final String path;
  final String message;
  final int at;
  const ScanError({
    required this.path,
    required this.message,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['message'] = Variable<String>(message);
    map['at'] = Variable<int>(at);
    return map;
  }

  ScanErrorsCompanion toCompanion(bool nullToAbsent) {
    return ScanErrorsCompanion(
      path: Value(path),
      message: Value(message),
      at: Value(at),
    );
  }

  factory ScanError.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanError(
      path: serializer.fromJson<String>(json['path']),
      message: serializer.fromJson<String>(json['message']),
      at: serializer.fromJson<int>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'path': serializer.toJson<String>(path),
      'message': serializer.toJson<String>(message),
      'at': serializer.toJson<int>(at),
    };
  }

  ScanError copyWith({String? path, String? message, int? at}) => ScanError(
    path: path ?? this.path,
    message: message ?? this.message,
    at: at ?? this.at,
  );
  ScanError copyWithCompanion(ScanErrorsCompanion data) {
    return ScanError(
      path: data.path.present ? data.path.value : this.path,
      message: data.message.present ? data.message.value : this.message,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanError(')
          ..write('path: $path, ')
          ..write('message: $message, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(path, message, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanError &&
          other.path == this.path &&
          other.message == this.message &&
          other.at == this.at);
}

class ScanErrorsCompanion extends UpdateCompanion<ScanError> {
  final Value<String> path;
  final Value<String> message;
  final Value<int> at;
  final Value<int> rowid;
  const ScanErrorsCompanion({
    this.path = const Value.absent(),
    this.message = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScanErrorsCompanion.insert({
    required String path,
    required String message,
    required int at,
    this.rowid = const Value.absent(),
  }) : path = Value(path),
       message = Value(message),
       at = Value(at);
  static Insertable<ScanError> custom({
    Expression<String>? path,
    Expression<String>? message,
    Expression<int>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (message != null) 'message': message,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScanErrorsCompanion copyWith({
    Value<String>? path,
    Value<String>? message,
    Value<int>? at,
    Value<int>? rowid,
  }) {
    return ScanErrorsCompanion(
      path: path ?? this.path,
      message: message ?? this.message,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (at.present) {
      map['at'] = Variable<int>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanErrorsCompanion(')
          ..write('path: $path, ')
          ..write('message: $message, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [trackId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final int trackId;
  final int addedAt;
  const Favorite({required this.trackId, required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<int>(trackId);
    map['added_at'] = Variable<int>(addedAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(trackId: Value(trackId), addedAt: Value(addedAt));
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      trackId: serializer.fromJson<int>(json['trackId']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<int>(trackId),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  Favorite copyWith({int? trackId, int? addedAt}) => Favorite(
    trackId: trackId ?? this.trackId,
    addedAt: addedAt ?? this.addedAt,
  );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('trackId: $trackId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.trackId == this.trackId &&
          other.addedAt == this.addedAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<int> trackId;
  final Value<int> addedAt;
  const FavoritesCompanion({
    this.trackId = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.trackId = const Value.absent(),
    required int addedAt,
  }) : addedAt = Value(addedAt);
  static Insertable<Favorite> custom({
    Expression<int>? trackId,
    Expression<int>? addedAt,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  FavoritesCompanion copyWith({Value<int>? trackId, Value<int>? addedAt}) {
    return FavoritesCompanion(
      trackId: trackId ?? this.trackId,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('trackId: $trackId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AlbumsTable albums = $AlbumsTable(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $ArtistsTable artists = $ArtistsTable(this);
  late final $TrackArtistsTable trackArtists = $TrackArtistsTable(this);
  late final $LibraryRootsTable libraryRoots = $LibraryRootsTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $PlaylistItemsTable playlistItems = $PlaylistItemsTable(this);
  late final $EqPresetsTable eqPresets = $EqPresetsTable(this);
  late final $PlaybackStateTable playbackState = $PlaybackStateTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $ScanErrorsTable scanErrors = $ScanErrorsTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final Index idxTracksAlbumId = Index(
    'idx_tracks_album_id',
    'CREATE INDEX idx_tracks_album_id ON tracks (album_id)',
  );
  late final Index idxTracksTitle = Index(
    'idx_tracks_title',
    'CREATE INDEX idx_tracks_title ON tracks (title)',
  );
  late final Index idxTracksArtist = Index(
    'idx_tracks_artist',
    'CREATE INDEX idx_tracks_artist ON tracks (artist)',
  );
  late final Index idxTracksAddedAt = Index(
    'idx_tracks_added_at',
    'CREATE INDEX idx_tracks_added_at ON tracks (added_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    albums,
    tracks,
    artists,
    trackArtists,
    libraryRoots,
    playlists,
    playlistItems,
    eqPresets,
    playbackState,
    settings,
    scanErrors,
    favorites,
    idxTracksAlbumId,
    idxTracksTitle,
    idxTracksArtist,
    idxTracksAddedAt,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'albums',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tracks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('track_artists', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'artists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('track_artists', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('favorites', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AlbumsTableCreateCompanionBuilder = AlbumsCompanion Function({
  Value<int> id,
  required String albumKey,
  Value<String> title,
  Value<String> albumArtist,
  Value<int?> year,
  Value<int> coverState,
  Value<int?> coverTrackId,
});
typedef $$AlbumsTableUpdateCompanionBuilder = AlbumsCompanion Function({
  Value<int> id,
  Value<String> albumKey,
  Value<String> title,
  Value<String> albumArtist,
  Value<int?> year,
  Value<int> coverState,
  Value<int?> coverTrackId,
});

final class $$AlbumsTableReferences
    extends BaseReferences<_$AppDatabase, $AlbumsTable, Album> {
  $$AlbumsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TracksTable, List<Track>> _tracksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tracks,
    aliasName: 'albums__id__tracks__album_id',
  );

  $$TracksTableProcessedTableManager get tracksRefs {
    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.albumId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tracksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AlbumsTableFilterComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumKey => $composableBuilder(
    column: $table.albumKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coverState => $composableBuilder(
    column: $table.coverState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coverTrackId => $composableBuilder(
    column: $table.coverTrackId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tracksRefs(
    Expression<bool> Function($$TracksTableFilterComposer f) f,
  ) {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AlbumsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumKey => $composableBuilder(
    column: $table.albumKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coverState => $composableBuilder(
    column: $table.coverState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coverTrackId => $composableBuilder(
    column: $table.coverTrackId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlbumsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get albumKey =>
      $composableBuilder(column: $table.albumKey, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get coverState => $composableBuilder(
    column: $table.coverState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get coverTrackId => $composableBuilder(
    column: $table.coverTrackId,
    builder: (column) => column,
  );

  Expression<T> tracksRefs<T extends Object>(
    Expression<T> Function($$TracksTableAnnotationComposer a) f,
  ) {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AlbumsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlbumsTable,
          Album,
          $$AlbumsTableFilterComposer,
          $$AlbumsTableOrderingComposer,
          $$AlbumsTableAnnotationComposer,
          $$AlbumsTableCreateCompanionBuilder,
          $$AlbumsTableUpdateCompanionBuilder,
          (Album, $$AlbumsTableReferences),
          Album,
          PrefetchHooks Function({bool tracksRefs})
        > {
  $$AlbumsTableTableManager(_$AppDatabase db, $AlbumsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlbumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlbumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlbumsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> albumKey = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> albumArtist = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<int> coverState = const Value.absent(),
                Value<int?> coverTrackId = const Value.absent(),
              }) => AlbumsCompanion(
                id: id,
                albumKey: albumKey,
                title: title,
                albumArtist: albumArtist,
                year: year,
                coverState: coverState,
                coverTrackId: coverTrackId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String albumKey,
                Value<String> title = const Value.absent(),
                Value<String> albumArtist = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<int> coverState = const Value.absent(),
                Value<int?> coverTrackId = const Value.absent(),
              }) => AlbumsCompanion.insert(
                id: id,
                albumKey: albumKey,
                title: title,
                albumArtist: albumArtist,
                year: year,
                coverState: coverState,
                coverTrackId: coverTrackId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlbumsTable, Album>(table),
                  $$AlbumsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tracksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tracksRefs) db.tracks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tracksRefs)
                    await $_getPrefetchedData<Album, $AlbumsTable, Track>(
                      currentTable: table,
                      referencedTable: $$AlbumsTableReferences._tracksRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$AlbumsTableReferences(db, table, p0).tracksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.albumId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AlbumsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlbumsTable,
      Album,
      $$AlbumsTableFilterComposer,
      $$AlbumsTableOrderingComposer,
      $$AlbumsTableAnnotationComposer,
      $$AlbumsTableCreateCompanionBuilder,
      $$AlbumsTableUpdateCompanionBuilder,
      (Album, $$AlbumsTableReferences),
      Album,
      PrefetchHooks Function({bool tracksRefs})
    >;
typedef $$TracksTableCreateCompanionBuilder = TracksCompanion Function({
  Value<int> id,
  required String path,
  Value<int> size,
  Value<int> mtime,
  Value<String> title,
  Value<String> artist,
  Value<String> albumArtist,
  Value<String> album,
  Value<int?> albumId,
  Value<int?> trackNo,
  Value<int?> discNo,
  Value<int?> year,
  Value<String> genre,
  Value<int> durationMs,
  Value<int?> sampleRate,
  Value<int?> bitDepth,
  Value<int?> bitrate,
  Value<int?> channels,
  Value<String> codec,
  Value<bool> hasEmbeddedLyrics,
  Value<String?> sidecarLrcPath,
  Value<String?> folderCoverPath,
  Value<bool> metadataError,
  Value<int> addedAt,
  Value<int> playCount,
  Value<int?> lastPlayedAt,
});
typedef $$TracksTableUpdateCompanionBuilder = TracksCompanion Function({
  Value<int> id,
  Value<String> path,
  Value<int> size,
  Value<int> mtime,
  Value<String> title,
  Value<String> artist,
  Value<String> albumArtist,
  Value<String> album,
  Value<int?> albumId,
  Value<int?> trackNo,
  Value<int?> discNo,
  Value<int?> year,
  Value<String> genre,
  Value<int> durationMs,
  Value<int?> sampleRate,
  Value<int?> bitDepth,
  Value<int?> bitrate,
  Value<int?> channels,
  Value<String> codec,
  Value<bool> hasEmbeddedLyrics,
  Value<String?> sidecarLrcPath,
  Value<String?> folderCoverPath,
  Value<bool> metadataError,
  Value<int> addedAt,
  Value<int> playCount,
  Value<int?> lastPlayedAt,
});

final class $$TracksTableReferences
    extends BaseReferences<_$AppDatabase, $TracksTable, Track> {
  $$TracksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AlbumsTable _albumIdTable(_$AppDatabase db) =>
      db.albums.createAlias('tracks__album_id__albums__id');

  $$AlbumsTableProcessedTableManager? get albumId {
    final $_column = $_itemColumn<int>('album_id');
    if ($_column == null) return null;
    final manager = $$AlbumsTableTableManager(
      $_db,
      $_db.albums,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_albumIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TrackArtistsTable, List<TrackArtist>>
  _trackArtistsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trackArtists,
    aliasName: 'tracks__id__track_artists__track_id',
  );

  $$TrackArtistsTableProcessedTableManager get trackArtistsRefs {
    final manager = $$TrackArtistsTableTableManager(
      $_db,
      $_db.trackArtists,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackArtistsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaylistItemsTable, List<PlaylistItem>>
  _playlistItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistItems,
    aliasName: 'tracks__id__playlist_items__track_id',
  );

  $$PlaylistItemsTableProcessedTableManager get playlistItemsRefs {
    final manager = $$PlaylistItemsTableTableManager(
      $_db,
      $_db.playlistItems,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FavoritesTable, List<Favorite>>
  _favoritesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.favorites,
    aliasName: 'tracks__id__favorites__track_id',
  );

  $$FavoritesTableProcessedTableManager get favoritesRefs {
    final manager = $$FavoritesTableTableManager(
      $_db,
      $_db.favorites,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_favoritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TracksTableFilterComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mtime => $composableBuilder(
    column: $table.mtime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackNo => $composableBuilder(
    column: $table.trackNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discNo => $composableBuilder(
    column: $table.discNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bitDepth => $composableBuilder(
    column: $table.bitDepth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bitrate => $composableBuilder(
    column: $table.bitrate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codec => $composableBuilder(
    column: $table.codec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasEmbeddedLyrics => $composableBuilder(
    column: $table.hasEmbeddedLyrics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sidecarLrcPath => $composableBuilder(
    column: $table.sidecarLrcPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderCoverPath => $composableBuilder(
    column: $table.folderCoverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get metadataError => $composableBuilder(
    column: $table.metadataError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AlbumsTableFilterComposer get albumId {
    final $$AlbumsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableFilterComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> trackArtistsRefs(
    Expression<bool> Function($$TrackArtistsTableFilterComposer f) f,
  ) {
    final $$TrackArtistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackArtists,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackArtistsTableFilterComposer(
            $db: $db,
            $table: $db.trackArtists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playlistItemsRefs(
    Expression<bool> Function($$PlaylistItemsTableFilterComposer f) f,
  ) {
    final $$PlaylistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistItems,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistItemsTableFilterComposer(
            $db: $db,
            $table: $db.playlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> favoritesRefs(
    Expression<bool> Function($$FavoritesTableFilterComposer f) f,
  ) {
    final $$FavoritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableFilterComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableOrderingComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mtime => $composableBuilder(
    column: $table.mtime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackNo => $composableBuilder(
    column: $table.trackNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discNo => $composableBuilder(
    column: $table.discNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bitDepth => $composableBuilder(
    column: $table.bitDepth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bitrate => $composableBuilder(
    column: $table.bitrate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codec => $composableBuilder(
    column: $table.codec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasEmbeddedLyrics => $composableBuilder(
    column: $table.hasEmbeddedLyrics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sidecarLrcPath => $composableBuilder(
    column: $table.sidecarLrcPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderCoverPath => $composableBuilder(
    column: $table.folderCoverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get metadataError => $composableBuilder(
    column: $table.metadataError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AlbumsTableOrderingComposer get albumId {
    final $$AlbumsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableOrderingComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<int> get mtime =>
      $composableBuilder(column: $table.mtime, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => column,
  );

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<int> get trackNo =>
      $composableBuilder(column: $table.trackNo, builder: (column) => column);

  GeneratedColumn<int> get discNo =>
      $composableBuilder(column: $table.discNo, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bitDepth =>
      $composableBuilder(column: $table.bitDepth, builder: (column) => column);

  GeneratedColumn<int> get bitrate =>
      $composableBuilder(column: $table.bitrate, builder: (column) => column);

  GeneratedColumn<int> get channels =>
      $composableBuilder(column: $table.channels, builder: (column) => column);

  GeneratedColumn<String> get codec =>
      $composableBuilder(column: $table.codec, builder: (column) => column);

  GeneratedColumn<bool> get hasEmbeddedLyrics => $composableBuilder(
    column: $table.hasEmbeddedLyrics,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sidecarLrcPath => $composableBuilder(
    column: $table.sidecarLrcPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folderCoverPath => $composableBuilder(
    column: $table.folderCoverPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get metadataError => $composableBuilder(
    column: $table.metadataError,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  GeneratedColumn<int> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  $$AlbumsTableAnnotationComposer get albumId {
    final $$AlbumsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableAnnotationComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> trackArtistsRefs<T extends Object>(
    Expression<T> Function($$TrackArtistsTableAnnotationComposer a) f,
  ) {
    final $$TrackArtistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackArtists,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackArtistsTableAnnotationComposer(
            $db: $db,
            $table: $db.trackArtists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playlistItemsRefs<T extends Object>(
    Expression<T> Function($$PlaylistItemsTableAnnotationComposer a) f,
  ) {
    final $$PlaylistItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistItems,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> favoritesRefs<T extends Object>(
    Expression<T> Function($$FavoritesTableAnnotationComposer a) f,
  ) {
    final $$FavoritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableAnnotationComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TracksTable,
          Track,
          $$TracksTableFilterComposer,
          $$TracksTableOrderingComposer,
          $$TracksTableAnnotationComposer,
          $$TracksTableCreateCompanionBuilder,
          $$TracksTableUpdateCompanionBuilder,
          (Track, $$TracksTableReferences),
          Track,
          PrefetchHooks Function({
            bool albumId,
            bool trackArtistsRefs,
            bool playlistItemsRefs,
            bool favoritesRefs,
          })
        > {
  $$TracksTableTableManager(_$AppDatabase db, $TracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<int> mtime = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String> albumArtist = const Value.absent(),
                Value<String> album = const Value.absent(),
                Value<int?> albumId = const Value.absent(),
                Value<int?> trackNo = const Value.absent(),
                Value<int?> discNo = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String> genre = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int?> sampleRate = const Value.absent(),
                Value<int?> bitDepth = const Value.absent(),
                Value<int?> bitrate = const Value.absent(),
                Value<int?> channels = const Value.absent(),
                Value<String> codec = const Value.absent(),
                Value<bool> hasEmbeddedLyrics = const Value.absent(),
                Value<String?> sidecarLrcPath = const Value.absent(),
                Value<String?> folderCoverPath = const Value.absent(),
                Value<bool> metadataError = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<int?> lastPlayedAt = const Value.absent(),
              }) => TracksCompanion(
                id: id,
                path: path,
                size: size,
                mtime: mtime,
                title: title,
                artist: artist,
                albumArtist: albumArtist,
                album: album,
                albumId: albumId,
                trackNo: trackNo,
                discNo: discNo,
                year: year,
                genre: genre,
                durationMs: durationMs,
                sampleRate: sampleRate,
                bitDepth: bitDepth,
                bitrate: bitrate,
                channels: channels,
                codec: codec,
                hasEmbeddedLyrics: hasEmbeddedLyrics,
                sidecarLrcPath: sidecarLrcPath,
                folderCoverPath: folderCoverPath,
                metadataError: metadataError,
                addedAt: addedAt,
                playCount: playCount,
                lastPlayedAt: lastPlayedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String path,
                Value<int> size = const Value.absent(),
                Value<int> mtime = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String> albumArtist = const Value.absent(),
                Value<String> album = const Value.absent(),
                Value<int?> albumId = const Value.absent(),
                Value<int?> trackNo = const Value.absent(),
                Value<int?> discNo = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String> genre = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int?> sampleRate = const Value.absent(),
                Value<int?> bitDepth = const Value.absent(),
                Value<int?> bitrate = const Value.absent(),
                Value<int?> channels = const Value.absent(),
                Value<String> codec = const Value.absent(),
                Value<bool> hasEmbeddedLyrics = const Value.absent(),
                Value<String?> sidecarLrcPath = const Value.absent(),
                Value<String?> folderCoverPath = const Value.absent(),
                Value<bool> metadataError = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<int?> lastPlayedAt = const Value.absent(),
              }) => TracksCompanion.insert(
                id: id,
                path: path,
                size: size,
                mtime: mtime,
                title: title,
                artist: artist,
                albumArtist: albumArtist,
                album: album,
                albumId: albumId,
                trackNo: trackNo,
                discNo: discNo,
                year: year,
                genre: genre,
                durationMs: durationMs,
                sampleRate: sampleRate,
                bitDepth: bitDepth,
                bitrate: bitrate,
                channels: channels,
                codec: codec,
                hasEmbeddedLyrics: hasEmbeddedLyrics,
                sidecarLrcPath: sidecarLrcPath,
                folderCoverPath: folderCoverPath,
                metadataError: metadataError,
                addedAt: addedAt,
                playCount: playCount,
                lastPlayedAt: lastPlayedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TracksTable, Track>(table),
                  $$TracksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                albumId = false,
                trackArtistsRefs = false,
                playlistItemsRefs = false,
                favoritesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (trackArtistsRefs) db.trackArtists,
                    if (playlistItemsRefs) db.playlistItems,
                    if (favoritesRefs) db.favorites,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (albumId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.albumId,
                            referencedTable: $$TracksTableReferences
                                ._albumIdTable(db),
                            referencedColumn: $$TracksTableReferences
                                ._albumIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (trackArtistsRefs)
                        await $_getPrefetchedData<
                          Track,
                          $TracksTable,
                          TrackArtist
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._trackArtistsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).trackArtistsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playlistItemsRefs)
                        await $_getPrefetchedData<
                          Track,
                          $TracksTable,
                          PlaylistItem
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._playlistItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).playlistItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (favoritesRefs)
                        await $_getPrefetchedData<
                          Track,
                          $TracksTable,
                          Favorite
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._favoritesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).favoritesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TracksTable,
      Track,
      $$TracksTableFilterComposer,
      $$TracksTableOrderingComposer,
      $$TracksTableAnnotationComposer,
      $$TracksTableCreateCompanionBuilder,
      $$TracksTableUpdateCompanionBuilder,
      (Track, $$TracksTableReferences),
      Track,
      PrefetchHooks Function({
        bool albumId,
        bool trackArtistsRefs,
        bool playlistItemsRefs,
        bool favoritesRefs,
      })
    >;
typedef $$ArtistsTableCreateCompanionBuilder = ArtistsCompanion Function({
  Value<int> id,
  required String nameKey,
  required String name,
});
typedef $$ArtistsTableUpdateCompanionBuilder = ArtistsCompanion Function({
  Value<int> id,
  Value<String> nameKey,
  Value<String> name,
});

final class $$ArtistsTableReferences
    extends BaseReferences<_$AppDatabase, $ArtistsTable, Artist> {
  $$ArtistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TrackArtistsTable, List<TrackArtist>>
  _trackArtistsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trackArtists,
    aliasName: 'artists__id__track_artists__artist_id',
  );

  $$TrackArtistsTableProcessedTableManager get trackArtistsRefs {
    final manager = $$TrackArtistsTableTableManager(
      $_db,
      $_db.trackArtists,
    ).filter((f) => f.artistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackArtistsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ArtistsTableFilterComposer
    extends Composer<_$AppDatabase, $ArtistsTable> {
  $$ArtistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> trackArtistsRefs(
    Expression<bool> Function($$TrackArtistsTableFilterComposer f) f,
  ) {
    final $$TrackArtistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackArtists,
      getReferencedColumn: (t) => t.artistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackArtistsTableFilterComposer(
            $db: $db,
            $table: $db.trackArtists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArtistsTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtistsTable> {
  $$ArtistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArtistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtistsTable> {
  $$ArtistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameKey =>
      $composableBuilder(column: $table.nameKey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> trackArtistsRefs<T extends Object>(
    Expression<T> Function($$TrackArtistsTableAnnotationComposer a) f,
  ) {
    final $$TrackArtistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackArtists,
      getReferencedColumn: (t) => t.artistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackArtistsTableAnnotationComposer(
            $db: $db,
            $table: $db.trackArtists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArtistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArtistsTable,
          Artist,
          $$ArtistsTableFilterComposer,
          $$ArtistsTableOrderingComposer,
          $$ArtistsTableAnnotationComposer,
          $$ArtistsTableCreateCompanionBuilder,
          $$ArtistsTableUpdateCompanionBuilder,
          (Artist, $$ArtistsTableReferences),
          Artist,
          PrefetchHooks Function({bool trackArtistsRefs})
        > {
  $$ArtistsTableTableManager(_$AppDatabase db, $ArtistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nameKey = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) => ArtistsCompanion(id: id, nameKey: nameKey, name: name),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nameKey,
            required String name,
          }) => ArtistsCompanion.insert(id: id, nameKey: nameKey, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ArtistsTable, Artist>(table),
                  $$ArtistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackArtistsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (trackArtistsRefs) db.trackArtists],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (trackArtistsRefs)
                    await $_getPrefetchedData<
                      Artist,
                      $ArtistsTable,
                      TrackArtist
                    >(
                      currentTable: table,
                      referencedTable: $$ArtistsTableReferences
                          ._trackArtistsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ArtistsTableReferences(
                        db,
                        table,
                        p0,
                      ).trackArtistsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.artistId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ArtistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArtistsTable,
      Artist,
      $$ArtistsTableFilterComposer,
      $$ArtistsTableOrderingComposer,
      $$ArtistsTableAnnotationComposer,
      $$ArtistsTableCreateCompanionBuilder,
      $$ArtistsTableUpdateCompanionBuilder,
      (Artist, $$ArtistsTableReferences),
      Artist,
      PrefetchHooks Function({bool trackArtistsRefs})
    >;
typedef $$TrackArtistsTableCreateCompanionBuilder =
    TrackArtistsCompanion Function({
      required int trackId,
      required int artistId,
      Value<int> rowid,
    });
typedef $$TrackArtistsTableUpdateCompanionBuilder =
    TrackArtistsCompanion Function({
      Value<int> trackId,
      Value<int> artistId,
      Value<int> rowid,
    });

final class $$TrackArtistsTableReferences
    extends BaseReferences<_$AppDatabase, $TrackArtistsTable, TrackArtist> {
  $$TrackArtistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$AppDatabase db) =>
      db.tracks.createAlias('track_artists__track_id__tracks__id');

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArtistsTable _artistIdTable(_$AppDatabase db) =>
      db.artists.createAlias('track_artists__artist_id__artists__id');

  $$ArtistsTableProcessedTableManager get artistId {
    final $_column = $_itemColumn<int>('artist_id')!;

    final manager = $$ArtistsTableTableManager(
      $_db,
      $_db.artists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_artistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackArtistsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackArtistsTable> {
  $$TrackArtistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArtistsTableFilterComposer get artistId {
    final $$ArtistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableFilterComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackArtistsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackArtistsTable> {
  $$TrackArtistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArtistsTableOrderingComposer get artistId {
    final $$ArtistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableOrderingComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackArtistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackArtistsTable> {
  $$TrackArtistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArtistsTableAnnotationComposer get artistId {
    final $$ArtistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.artists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableAnnotationComposer(
            $db: $db,
            $table: $db.artists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackArtistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackArtistsTable,
          TrackArtist,
          $$TrackArtistsTableFilterComposer,
          $$TrackArtistsTableOrderingComposer,
          $$TrackArtistsTableAnnotationComposer,
          $$TrackArtistsTableCreateCompanionBuilder,
          $$TrackArtistsTableUpdateCompanionBuilder,
          (TrackArtist, $$TrackArtistsTableReferences),
          TrackArtist,
          PrefetchHooks Function({bool trackId, bool artistId})
        > {
  $$TrackArtistsTableTableManager(_$AppDatabase db, $TrackArtistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackArtistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackArtistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackArtistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> trackId = const Value.absent(),
                Value<int> artistId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackArtistsCompanion(
                trackId: trackId,
                artistId: artistId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int trackId,
                required int artistId,
                Value<int> rowid = const Value.absent(),
              }) => TrackArtistsCompanion.insert(
                trackId: trackId,
                artistId: artistId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrackArtistsTable, TrackArtist>(table),
                  $$TrackArtistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false, artistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: $$TrackArtistsTableReferences
                            ._trackIdTable(db),
                        referencedColumn: $$TrackArtistsTableReferences
                            ._trackIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (artistId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.artistId,
                        referencedTable: $$TrackArtistsTableReferences
                            ._artistIdTable(db),
                        referencedColumn: $$TrackArtistsTableReferences
                            ._artistIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrackArtistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackArtistsTable,
      TrackArtist,
      $$TrackArtistsTableFilterComposer,
      $$TrackArtistsTableOrderingComposer,
      $$TrackArtistsTableAnnotationComposer,
      $$TrackArtistsTableCreateCompanionBuilder,
      $$TrackArtistsTableUpdateCompanionBuilder,
      (TrackArtist, $$TrackArtistsTableReferences),
      TrackArtist,
      PrefetchHooks Function({bool trackId, bool artistId})
    >;
typedef $$LibraryRootsTableCreateCompanionBuilder =
    LibraryRootsCompanion Function({
      Value<int> id,
      required String path,
      Value<bool> excluded,
    });
typedef $$LibraryRootsTableUpdateCompanionBuilder =
    LibraryRootsCompanion Function({
      Value<int> id,
      Value<String> path,
      Value<bool> excluded,
    });

class $$LibraryRootsTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryRootsTable> {
  $$LibraryRootsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get excluded => $composableBuilder(
    column: $table.excluded,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LibraryRootsTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryRootsTable> {
  $$LibraryRootsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get excluded => $composableBuilder(
    column: $table.excluded,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibraryRootsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryRootsTable> {
  $$LibraryRootsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<bool> get excluded =>
      $composableBuilder(column: $table.excluded, builder: (column) => column);
}

class $$LibraryRootsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryRootsTable,
          LibraryRoot,
          $$LibraryRootsTableFilterComposer,
          $$LibraryRootsTableOrderingComposer,
          $$LibraryRootsTableAnnotationComposer,
          $$LibraryRootsTableCreateCompanionBuilder,
          $$LibraryRootsTableUpdateCompanionBuilder,
          (
            LibraryRoot,
            BaseReferences<_$AppDatabase, $LibraryRootsTable, LibraryRoot>,
          ),
          LibraryRoot,
          PrefetchHooks Function()
        > {
  $$LibraryRootsTableTableManager(_$AppDatabase db, $LibraryRootsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryRootsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryRootsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryRootsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<bool> excluded = const Value.absent(),
          }) => LibraryRootsCompanion(id: id, path: path, excluded: excluded),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String path,
                Value<bool> excluded = const Value.absent(),
              }) => LibraryRootsCompanion.insert(
                id: id,
                path: path,
                excluded: excluded,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LibraryRootsTable, LibraryRoot>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LibraryRootsTable,
                    LibraryRoot
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LibraryRootsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryRootsTable,
      LibraryRoot,
      $$LibraryRootsTableFilterComposer,
      $$LibraryRootsTableOrderingComposer,
      $$LibraryRootsTableAnnotationComposer,
      $$LibraryRootsTableCreateCompanionBuilder,
      $$LibraryRootsTableUpdateCompanionBuilder,
      (
        LibraryRoot,
        BaseReferences<_$AppDatabase, $LibraryRootsTable, LibraryRoot>,
      ),
      LibraryRoot,
      PrefetchHooks Function()
    >;
typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  required String name,
  required int createdAt,
  required int updatedAt,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> createdAt,
  Value<int> updatedAt,
});

final class $$PlaylistsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistsTable, Playlist> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistItemsTable, List<PlaylistItem>>
  _playlistItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistItems,
    aliasName: 'playlists__id__playlist_items__playlist_id',
  );

  $$PlaylistItemsTableProcessedTableManager get playlistItemsRefs {
    final manager = $$PlaylistItemsTableTableManager(
      $_db,
      $_db.playlistItems,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playlistItemsRefs(
    Expression<bool> Function($$PlaylistItemsTableFilterComposer f) f,
  ) {
    final $$PlaylistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistItems,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistItemsTableFilterComposer(
            $db: $db,
            $table: $db.playlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> playlistItemsRefs<T extends Object>(
    Expression<T> Function($$PlaylistItemsTableAnnotationComposer a) f,
  ) {
    final $$PlaylistItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistItems,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistsTable,
          Playlist,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (Playlist, $$PlaylistsTableReferences),
          Playlist,
          PrefetchHooks Function({bool playlistItemsRefs})
        > {
  $$PlaylistsTableTableManager(_$AppDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => PlaylistsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int createdAt,
                required int updatedAt,
              }) => PlaylistsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistsTable, Playlist>(table),
                  $$PlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistItemsRefs) db.playlistItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistItemsRefs)
                    await $_getPrefetchedData<
                      Playlist,
                      $PlaylistsTable,
                      PlaylistItem
                    >(
                      currentTable: table,
                      referencedTable: $$PlaylistsTableReferences
                          ._playlistItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PlaylistsTableReferences(
                            db,
                            table,
                            p0,
                          ).playlistItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.playlistId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistsTable,
      Playlist,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (Playlist, $$PlaylistsTableReferences),
      Playlist,
      PrefetchHooks Function({bool playlistItemsRefs})
    >;
typedef $$PlaylistItemsTableCreateCompanionBuilder =
    PlaylistItemsCompanion Function({
      required int playlistId,
      required int position,
      required int trackId,
      Value<int> rowid,
    });
typedef $$PlaylistItemsTableUpdateCompanionBuilder =
    PlaylistItemsCompanion Function({
      Value<int> playlistId,
      Value<int> position,
      Value<int> trackId,
      Value<int> rowid,
    });

final class $$PlaylistItemsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistItemsTable, PlaylistItem> {
  $$PlaylistItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias('playlist_items__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TracksTable _trackIdTable(_$AppDatabase db) =>
      db.tracks.createAlias('playlist_items__track_id__tracks__id');

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaylistItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistItemsTable> {
  $$PlaylistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistItemsTable> {
  $$PlaylistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistItemsTable> {
  $$PlaylistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistItemsTable,
          PlaylistItem,
          $$PlaylistItemsTableFilterComposer,
          $$PlaylistItemsTableOrderingComposer,
          $$PlaylistItemsTableAnnotationComposer,
          $$PlaylistItemsTableCreateCompanionBuilder,
          $$PlaylistItemsTableUpdateCompanionBuilder,
          (PlaylistItem, $$PlaylistItemsTableReferences),
          PlaylistItem,
          PrefetchHooks Function({bool playlistId, bool trackId})
        > {
  $$PlaylistItemsTableTableManager(_$AppDatabase db, $PlaylistItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> playlistId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> trackId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistItemsCompanion(
                playlistId: playlistId,
                position: position,
                trackId: trackId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int playlistId,
                required int position,
                required int trackId,
                Value<int> rowid = const Value.absent(),
              }) => PlaylistItemsCompanion.insert(
                playlistId: playlistId,
                position: position,
                trackId: trackId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistItemsTable, PlaylistItem>(table),
                  $$PlaylistItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false, trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.playlistId,
                        referencedTable: $$PlaylistItemsTableReferences
                            ._playlistIdTable(db),
                        referencedColumn: $$PlaylistItemsTableReferences
                            ._playlistIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: $$PlaylistItemsTableReferences
                            ._trackIdTable(db),
                        referencedColumn: $$PlaylistItemsTableReferences
                            ._trackIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistItemsTable,
      PlaylistItem,
      $$PlaylistItemsTableFilterComposer,
      $$PlaylistItemsTableOrderingComposer,
      $$PlaylistItemsTableAnnotationComposer,
      $$PlaylistItemsTableCreateCompanionBuilder,
      $$PlaylistItemsTableUpdateCompanionBuilder,
      (PlaylistItem, $$PlaylistItemsTableReferences),
      PlaylistItem,
      PrefetchHooks Function({bool playlistId, bool trackId})
    >;
typedef $$EqPresetsTableCreateCompanionBuilder = EqPresetsCompanion Function({
  Value<int> id,
  required String name,
  Value<bool> builtin,
  required String gainsJson,
  Value<double> preamp,
});
typedef $$EqPresetsTableUpdateCompanionBuilder = EqPresetsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<bool> builtin,
  Value<String> gainsJson,
  Value<double> preamp,
});

class $$EqPresetsTableFilterComposer
    extends Composer<_$AppDatabase, $EqPresetsTable> {
  $$EqPresetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get builtin => $composableBuilder(
    column: $table.builtin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gainsJson => $composableBuilder(
    column: $table.gainsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get preamp => $composableBuilder(
    column: $table.preamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EqPresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $EqPresetsTable> {
  $$EqPresetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get builtin => $composableBuilder(
    column: $table.builtin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gainsJson => $composableBuilder(
    column: $table.gainsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get preamp => $composableBuilder(
    column: $table.preamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EqPresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EqPresetsTable> {
  $$EqPresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get builtin =>
      $composableBuilder(column: $table.builtin, builder: (column) => column);

  GeneratedColumn<String> get gainsJson =>
      $composableBuilder(column: $table.gainsJson, builder: (column) => column);

  GeneratedColumn<double> get preamp =>
      $composableBuilder(column: $table.preamp, builder: (column) => column);
}

class $$EqPresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EqPresetsTable,
          EqPreset,
          $$EqPresetsTableFilterComposer,
          $$EqPresetsTableOrderingComposer,
          $$EqPresetsTableAnnotationComposer,
          $$EqPresetsTableCreateCompanionBuilder,
          $$EqPresetsTableUpdateCompanionBuilder,
          (EqPreset, BaseReferences<_$AppDatabase, $EqPresetsTable, EqPreset>),
          EqPreset,
          PrefetchHooks Function()
        > {
  $$EqPresetsTableTableManager(_$AppDatabase db, $EqPresetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EqPresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EqPresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EqPresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> builtin = const Value.absent(),
                Value<String> gainsJson = const Value.absent(),
                Value<double> preamp = const Value.absent(),
              }) => EqPresetsCompanion(
                id: id,
                name: name,
                builtin: builtin,
                gainsJson: gainsJson,
                preamp: preamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<bool> builtin = const Value.absent(),
                required String gainsJson,
                Value<double> preamp = const Value.absent(),
              }) => EqPresetsCompanion.insert(
                id: id,
                name: name,
                builtin: builtin,
                gainsJson: gainsJson,
                preamp: preamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EqPresetsTable, EqPreset>(table),
                  BaseReferences<_$AppDatabase, $EqPresetsTable, EqPreset>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EqPresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EqPresetsTable,
      EqPreset,
      $$EqPresetsTableFilterComposer,
      $$EqPresetsTableOrderingComposer,
      $$EqPresetsTableAnnotationComposer,
      $$EqPresetsTableCreateCompanionBuilder,
      $$EqPresetsTableUpdateCompanionBuilder,
      (EqPreset, BaseReferences<_$AppDatabase, $EqPresetsTable, EqPreset>),
      EqPreset,
      PrefetchHooks Function()
    >;
typedef $$PlaybackStateTableCreateCompanionBuilder =
    PlaybackStateCompanion Function({
      Value<int> id,
      Value<String> queueJson,
      Value<String> shuffledJson,
      Value<int> currentIndex,
      Value<int> positionMs,
      Value<int> loopMode,
      Value<bool> shuffle,
    });
typedef $$PlaybackStateTableUpdateCompanionBuilder =
    PlaybackStateCompanion Function({
      Value<int> id,
      Value<String> queueJson,
      Value<String> shuffledJson,
      Value<int> currentIndex,
      Value<int> positionMs,
      Value<int> loopMode,
      Value<bool> shuffle,
    });

class $$PlaybackStateTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackStateTable> {
  $$PlaybackStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get queueJson => $composableBuilder(
    column: $table.queueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shuffledJson => $composableBuilder(
    column: $table.shuffledJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentIndex => $composableBuilder(
    column: $table.currentIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get loopMode => $composableBuilder(
    column: $table.loopMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get shuffle => $composableBuilder(
    column: $table.shuffle,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaybackStateTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackStateTable> {
  $$PlaybackStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get queueJson => $composableBuilder(
    column: $table.queueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shuffledJson => $composableBuilder(
    column: $table.shuffledJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentIndex => $composableBuilder(
    column: $table.currentIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get loopMode => $composableBuilder(
    column: $table.loopMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get shuffle => $composableBuilder(
    column: $table.shuffle,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaybackStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackStateTable> {
  $$PlaybackStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get queueJson =>
      $composableBuilder(column: $table.queueJson, builder: (column) => column);

  GeneratedColumn<String> get shuffledJson => $composableBuilder(
    column: $table.shuffledJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentIndex => $composableBuilder(
    column: $table.currentIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get loopMode =>
      $composableBuilder(column: $table.loopMode, builder: (column) => column);

  GeneratedColumn<bool> get shuffle =>
      $composableBuilder(column: $table.shuffle, builder: (column) => column);
}

class $$PlaybackStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaybackStateTable,
          PlaybackStateData,
          $$PlaybackStateTableFilterComposer,
          $$PlaybackStateTableOrderingComposer,
          $$PlaybackStateTableAnnotationComposer,
          $$PlaybackStateTableCreateCompanionBuilder,
          $$PlaybackStateTableUpdateCompanionBuilder,
          (
            PlaybackStateData,
            BaseReferences<
              _$AppDatabase,
              $PlaybackStateTable,
              PlaybackStateData
            >,
          ),
          PlaybackStateData,
          PrefetchHooks Function()
        > {
  $$PlaybackStateTableTableManager(_$AppDatabase db, $PlaybackStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaybackStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> queueJson = const Value.absent(),
                Value<String> shuffledJson = const Value.absent(),
                Value<int> currentIndex = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int> loopMode = const Value.absent(),
                Value<bool> shuffle = const Value.absent(),
              }) => PlaybackStateCompanion(
                id: id,
                queueJson: queueJson,
                shuffledJson: shuffledJson,
                currentIndex: currentIndex,
                positionMs: positionMs,
                loopMode: loopMode,
                shuffle: shuffle,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> queueJson = const Value.absent(),
                Value<String> shuffledJson = const Value.absent(),
                Value<int> currentIndex = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int> loopMode = const Value.absent(),
                Value<bool> shuffle = const Value.absent(),
              }) => PlaybackStateCompanion.insert(
                id: id,
                queueJson: queueJson,
                shuffledJson: shuffledJson,
                currentIndex: currentIndex,
                positionMs: positionMs,
                loopMode: loopMode,
                shuffle: shuffle,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaybackStateTable, PlaybackStateData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PlaybackStateTable,
                    PlaybackStateData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaybackStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaybackStateTable,
      PlaybackStateData,
      $$PlaybackStateTableFilterComposer,
      $$PlaybackStateTableOrderingComposer,
      $$PlaybackStateTableAnnotationComposer,
      $$PlaybackStateTableCreateCompanionBuilder,
      $$PlaybackStateTableUpdateCompanionBuilder,
      (
        PlaybackStateData,
        BaseReferences<_$AppDatabase, $PlaybackStateTable, PlaybackStateData>,
      ),
      PlaybackStateData,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$ScanErrorsTableCreateCompanionBuilder = ScanErrorsCompanion Function({
  required String path,
  required String message,
  required int at,
  Value<int> rowid,
});
typedef $$ScanErrorsTableUpdateCompanionBuilder = ScanErrorsCompanion Function({
  Value<String> path,
  Value<String> message,
  Value<int> at,
  Value<int> rowid,
});

class $$ScanErrorsTableFilterComposer
    extends Composer<_$AppDatabase, $ScanErrorsTable> {
  $$ScanErrorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScanErrorsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanErrorsTable> {
  $$ScanErrorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScanErrorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanErrorsTable> {
  $$ScanErrorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$ScanErrorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScanErrorsTable,
          ScanError,
          $$ScanErrorsTableFilterComposer,
          $$ScanErrorsTableOrderingComposer,
          $$ScanErrorsTableAnnotationComposer,
          $$ScanErrorsTableCreateCompanionBuilder,
          $$ScanErrorsTableUpdateCompanionBuilder,
          (
            ScanError,
            BaseReferences<_$AppDatabase, $ScanErrorsTable, ScanError>,
          ),
          ScanError,
          PrefetchHooks Function()
        > {
  $$ScanErrorsTableTableManager(_$AppDatabase db, $ScanErrorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanErrorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanErrorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanErrorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> path = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<int> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScanErrorsCompanion(
                path: path,
                message: message,
                at: at,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String path,
                required String message,
                required int at,
                Value<int> rowid = const Value.absent(),
              }) => ScanErrorsCompanion.insert(
                path: path,
                message: message,
                at: at,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScanErrorsTable, ScanError>(table),
                  BaseReferences<_$AppDatabase, $ScanErrorsTable, ScanError>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScanErrorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScanErrorsTable,
      ScanError,
      $$ScanErrorsTableFilterComposer,
      $$ScanErrorsTableOrderingComposer,
      $$ScanErrorsTableAnnotationComposer,
      $$ScanErrorsTableCreateCompanionBuilder,
      $$ScanErrorsTableUpdateCompanionBuilder,
      (ScanError, BaseReferences<_$AppDatabase, $ScanErrorsTable, ScanError>),
      ScanError,
      PrefetchHooks Function()
    >;
typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  Value<int> trackId,
  required int addedAt,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<int> trackId,
  Value<int> addedAt,
});

final class $$FavoritesTableReferences
    extends BaseReferences<_$AppDatabase, $FavoritesTable, Favorite> {
  $$FavoritesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$AppDatabase db) =>
      db.tracks.createAlias('favorites__track_id__tracks__id');

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (Favorite, $$FavoritesTableReferences),
          Favorite,
          PrefetchHooks Function({bool trackId})
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> trackId = const Value.absent(),
            Value<int> addedAt = const Value.absent(),
          }) => FavoritesCompanion(trackId: trackId, addedAt: addedAt),
          createCompanionCallback: ({
            Value<int> trackId = const Value.absent(),
            required int addedAt,
          }) => FavoritesCompanion.insert(trackId: trackId, addedAt: addedAt),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoritesTable, Favorite>(table),
                  $$FavoritesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: $$FavoritesTableReferences
                            ._trackIdTable(db),
                        referencedColumn: $$FavoritesTableReferences
                            ._trackIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (Favorite, $$FavoritesTableReferences),
      Favorite,
      PrefetchHooks Function({bool trackId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AlbumsTableTableManager get albums =>
      $$AlbumsTableTableManager(_db, _db.albums);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$ArtistsTableTableManager get artists =>
      $$ArtistsTableTableManager(_db, _db.artists);
  $$TrackArtistsTableTableManager get trackArtists =>
      $$TrackArtistsTableTableManager(_db, _db.trackArtists);
  $$LibraryRootsTableTableManager get libraryRoots =>
      $$LibraryRootsTableTableManager(_db, _db.libraryRoots);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$PlaylistItemsTableTableManager get playlistItems =>
      $$PlaylistItemsTableTableManager(_db, _db.playlistItems);
  $$EqPresetsTableTableManager get eqPresets =>
      $$EqPresetsTableTableManager(_db, _db.eqPresets);
  $$PlaybackStateTableTableManager get playbackState =>
      $$PlaybackStateTableTableManager(_db, _db.playbackState);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$ScanErrorsTableTableManager get scanErrors =>
      $$ScanErrorsTableTableManager(_db, _db.scanErrors);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
}
