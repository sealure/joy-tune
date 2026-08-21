// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalFavoritesTable extends LocalFavorites
    with TableInfo<$LocalFavoritesTable, LocalFavorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalFavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
      'song_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
      'artist', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
      'album', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _picIdMeta = const VerificationMeta('picId');
  @override
  late final GeneratedColumn<String> picId = GeneratedColumn<String>(
      'pic_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lyricIdMeta =
      const VerificationMeta('lyricId');
  @override
  late final GeneratedColumn<String> lyricId = GeneratedColumn<String>(
      'lyric_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _audioUrlMeta =
      const VerificationMeta('audioUrl');
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
      'audio_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lyricsUrlMeta =
      const VerificationMeta('lyricsUrl');
  @override
  late final GeneratedColumn<String> lyricsUrl = GeneratedColumn<String>(
      'lyrics_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncedEverMeta =
      const VerificationMeta('syncedEver');
  @override
  late final GeneratedColumn<bool> syncedEver = GeneratedColumn<bool>(
      'synced_ever', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced_ever" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        songId,
        source,
        name,
        artist,
        album,
        picId,
        lyricId,
        audioUrl,
        coverUrl,
        lyricsUrl,
        deleted,
        isSynced,
        syncedEver,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_favorites';
  @override
  VerificationContext validateIntegrity(Insertable<LocalFavorite> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('song_id')) {
      context.handle(_songIdMeta,
          songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta));
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(_artistMeta,
          artist.isAcceptableOrUnknown(data['artist']!, _artistMeta));
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('album')) {
      context.handle(
          _albumMeta, album.isAcceptableOrUnknown(data['album']!, _albumMeta));
    }
    if (data.containsKey('pic_id')) {
      context.handle(
          _picIdMeta, picId.isAcceptableOrUnknown(data['pic_id']!, _picIdMeta));
    }
    if (data.containsKey('lyric_id')) {
      context.handle(_lyricIdMeta,
          lyricId.isAcceptableOrUnknown(data['lyric_id']!, _lyricIdMeta));
    }
    if (data.containsKey('audio_url')) {
      context.handle(_audioUrlMeta,
          audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta));
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('lyrics_url')) {
      context.handle(_lyricsUrlMeta,
          lyricsUrl.isAcceptableOrUnknown(data['lyrics_url']!, _lyricsUrlMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('synced_ever')) {
      context.handle(
          _syncedEverMeta,
          syncedEver.isAcceptableOrUnknown(
              data['synced_ever']!, _syncedEverMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {songId, source};
  @override
  LocalFavorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalFavorite(
      songId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist'])!,
      album: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album'])!,
      picId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pic_id']),
      lyricId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lyric_id']),
      audioUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_url']),
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url']),
      lyricsUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lyrics_url']),
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      syncedEver: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced_ever'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalFavoritesTable createAlias(String alias) {
    return $LocalFavoritesTable(attachedDatabase, alias);
  }
}

class LocalFavorite extends DataClass implements Insertable<LocalFavorite> {
  /// 歌曲 ID（原始音源 ID）
  final String songId;

  /// 音源标识（netease/qqmusic/joox 等）
  final String source;

  /// 歌曲名
  final String name;

  /// 歌手
  final String artist;

  /// 专辑
  final String album;

  /// 封面图 pic_id（按需懒加载）
  final String? picId;

  /// 歌词 ID
  final String? lyricId;

  /// 播放地址
  final String? audioUrl;

  /// 封面 URL
  final String? coverUrl;

  /// 歌词 LRC 地址
  final String? lyricsUrl;

  /// soft delete 标记（1=已取消收藏待同步删除）
  final bool deleted;

  /// 是否已同步到服务端（0=待同步）
  final bool isSynced;

  /// 是否曾成功同步过（用于删除同步：曾同步的删除需调 DELETE，未同步的直接物理删）
  final bool syncedEver;

  /// 收藏时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;
  const LocalFavorite(
      {required this.songId,
      required this.source,
      required this.name,
      required this.artist,
      required this.album,
      this.picId,
      this.lyricId,
      this.audioUrl,
      this.coverUrl,
      this.lyricsUrl,
      required this.deleted,
      required this.isSynced,
      required this.syncedEver,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['song_id'] = Variable<String>(songId);
    map['source'] = Variable<String>(source);
    map['name'] = Variable<String>(name);
    map['artist'] = Variable<String>(artist);
    map['album'] = Variable<String>(album);
    if (!nullToAbsent || picId != null) {
      map['pic_id'] = Variable<String>(picId);
    }
    if (!nullToAbsent || lyricId != null) {
      map['lyric_id'] = Variable<String>(lyricId);
    }
    if (!nullToAbsent || audioUrl != null) {
      map['audio_url'] = Variable<String>(audioUrl);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || lyricsUrl != null) {
      map['lyrics_url'] = Variable<String>(lyricsUrl);
    }
    map['deleted'] = Variable<bool>(deleted);
    map['is_synced'] = Variable<bool>(isSynced);
    map['synced_ever'] = Variable<bool>(syncedEver);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalFavoritesCompanion toCompanion(bool nullToAbsent) {
    return LocalFavoritesCompanion(
      songId: Value(songId),
      source: Value(source),
      name: Value(name),
      artist: Value(artist),
      album: Value(album),
      picId:
          picId == null && nullToAbsent ? const Value.absent() : Value(picId),
      lyricId: lyricId == null && nullToAbsent
          ? const Value.absent()
          : Value(lyricId),
      audioUrl: audioUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUrl),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      lyricsUrl: lyricsUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(lyricsUrl),
      deleted: Value(deleted),
      isSynced: Value(isSynced),
      syncedEver: Value(syncedEver),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalFavorite.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalFavorite(
      songId: serializer.fromJson<String>(json['songId']),
      source: serializer.fromJson<String>(json['source']),
      name: serializer.fromJson<String>(json['name']),
      artist: serializer.fromJson<String>(json['artist']),
      album: serializer.fromJson<String>(json['album']),
      picId: serializer.fromJson<String?>(json['picId']),
      lyricId: serializer.fromJson<String?>(json['lyricId']),
      audioUrl: serializer.fromJson<String?>(json['audioUrl']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      lyricsUrl: serializer.fromJson<String?>(json['lyricsUrl']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncedEver: serializer.fromJson<bool>(json['syncedEver']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'songId': serializer.toJson<String>(songId),
      'source': serializer.toJson<String>(source),
      'name': serializer.toJson<String>(name),
      'artist': serializer.toJson<String>(artist),
      'album': serializer.toJson<String>(album),
      'picId': serializer.toJson<String?>(picId),
      'lyricId': serializer.toJson<String?>(lyricId),
      'audioUrl': serializer.toJson<String?>(audioUrl),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'lyricsUrl': serializer.toJson<String?>(lyricsUrl),
      'deleted': serializer.toJson<bool>(deleted),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncedEver': serializer.toJson<bool>(syncedEver),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalFavorite copyWith(
          {String? songId,
          String? source,
          String? name,
          String? artist,
          String? album,
          Value<String?> picId = const Value.absent(),
          Value<String?> lyricId = const Value.absent(),
          Value<String?> audioUrl = const Value.absent(),
          Value<String?> coverUrl = const Value.absent(),
          Value<String?> lyricsUrl = const Value.absent(),
          bool? deleted,
          bool? isSynced,
          bool? syncedEver,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      LocalFavorite(
        songId: songId ?? this.songId,
        source: source ?? this.source,
        name: name ?? this.name,
        artist: artist ?? this.artist,
        album: album ?? this.album,
        picId: picId.present ? picId.value : this.picId,
        lyricId: lyricId.present ? lyricId.value : this.lyricId,
        audioUrl: audioUrl.present ? audioUrl.value : this.audioUrl,
        coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
        lyricsUrl: lyricsUrl.present ? lyricsUrl.value : this.lyricsUrl,
        deleted: deleted ?? this.deleted,
        isSynced: isSynced ?? this.isSynced,
        syncedEver: syncedEver ?? this.syncedEver,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalFavorite copyWithCompanion(LocalFavoritesCompanion data) {
    return LocalFavorite(
      songId: data.songId.present ? data.songId.value : this.songId,
      source: data.source.present ? data.source.value : this.source,
      name: data.name.present ? data.name.value : this.name,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      picId: data.picId.present ? data.picId.value : this.picId,
      lyricId: data.lyricId.present ? data.lyricId.value : this.lyricId,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      lyricsUrl: data.lyricsUrl.present ? data.lyricsUrl.value : this.lyricsUrl,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      syncedEver:
          data.syncedEver.present ? data.syncedEver.value : this.syncedEver,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalFavorite(')
          ..write('songId: $songId, ')
          ..write('source: $source, ')
          ..write('name: $name, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('picId: $picId, ')
          ..write('lyricId: $lyricId, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('lyricsUrl: $lyricsUrl, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncedEver: $syncedEver, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      songId,
      source,
      name,
      artist,
      album,
      picId,
      lyricId,
      audioUrl,
      coverUrl,
      lyricsUrl,
      deleted,
      isSynced,
      syncedEver,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFavorite &&
          other.songId == this.songId &&
          other.source == this.source &&
          other.name == this.name &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.picId == this.picId &&
          other.lyricId == this.lyricId &&
          other.audioUrl == this.audioUrl &&
          other.coverUrl == this.coverUrl &&
          other.lyricsUrl == this.lyricsUrl &&
          other.deleted == this.deleted &&
          other.isSynced == this.isSynced &&
          other.syncedEver == this.syncedEver &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalFavoritesCompanion extends UpdateCompanion<LocalFavorite> {
  final Value<String> songId;
  final Value<String> source;
  final Value<String> name;
  final Value<String> artist;
  final Value<String> album;
  final Value<String?> picId;
  final Value<String?> lyricId;
  final Value<String?> audioUrl;
  final Value<String?> coverUrl;
  final Value<String?> lyricsUrl;
  final Value<bool> deleted;
  final Value<bool> isSynced;
  final Value<bool> syncedEver;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalFavoritesCompanion({
    this.songId = const Value.absent(),
    this.source = const Value.absent(),
    this.name = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.picId = const Value.absent(),
    this.lyricId = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.lyricsUrl = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncedEver = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalFavoritesCompanion.insert({
    required String songId,
    required String source,
    required String name,
    required String artist,
    this.album = const Value.absent(),
    this.picId = const Value.absent(),
    this.lyricId = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.lyricsUrl = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncedEver = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : songId = Value(songId),
        source = Value(source),
        name = Value(name),
        artist = Value(artist);
  static Insertable<LocalFavorite> custom({
    Expression<String>? songId,
    Expression<String>? source,
    Expression<String>? name,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<String>? picId,
    Expression<String>? lyricId,
    Expression<String>? audioUrl,
    Expression<String>? coverUrl,
    Expression<String>? lyricsUrl,
    Expression<bool>? deleted,
    Expression<bool>? isSynced,
    Expression<bool>? syncedEver,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (songId != null) 'song_id': songId,
      if (source != null) 'source': source,
      if (name != null) 'name': name,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (picId != null) 'pic_id': picId,
      if (lyricId != null) 'lyric_id': lyricId,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (lyricsUrl != null) 'lyrics_url': lyricsUrl,
      if (deleted != null) 'deleted': deleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncedEver != null) 'synced_ever': syncedEver,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalFavoritesCompanion copyWith(
      {Value<String>? songId,
      Value<String>? source,
      Value<String>? name,
      Value<String>? artist,
      Value<String>? album,
      Value<String?>? picId,
      Value<String?>? lyricId,
      Value<String?>? audioUrl,
      Value<String?>? coverUrl,
      Value<String?>? lyricsUrl,
      Value<bool>? deleted,
      Value<bool>? isSynced,
      Value<bool>? syncedEver,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalFavoritesCompanion(
      songId: songId ?? this.songId,
      source: source ?? this.source,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      picId: picId ?? this.picId,
      lyricId: lyricId ?? this.lyricId,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      lyricsUrl: lyricsUrl ?? this.lyricsUrl,
      deleted: deleted ?? this.deleted,
      isSynced: isSynced ?? this.isSynced,
      syncedEver: syncedEver ?? this.syncedEver,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (picId.present) {
      map['pic_id'] = Variable<String>(picId.value);
    }
    if (lyricId.present) {
      map['lyric_id'] = Variable<String>(lyricId.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (lyricsUrl.present) {
      map['lyrics_url'] = Variable<String>(lyricsUrl.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncedEver.present) {
      map['synced_ever'] = Variable<bool>(syncedEver.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalFavoritesCompanion(')
          ..write('songId: $songId, ')
          ..write('source: $source, ')
          ..write('name: $name, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('picId: $picId, ')
          ..write('lyricId: $lyricId, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('lyricsUrl: $lyricsUrl, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncedEver: $syncedEver, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPlaylistsTable extends LocalPlaylists
    with TableInfo<$LocalPlaylistsTable, LocalPlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
      'remote_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _coverPicIdMeta =
      const VerificationMeta('coverPicId');
  @override
  late final GeneratedColumn<String> coverPicId = GeneratedColumn<String>(
      'cover_pic_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverSourceMeta =
      const VerificationMeta('coverSource');
  @override
  late final GeneratedColumn<String> coverSource = GeneratedColumn<String>(
      'cover_source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isPublicMeta =
      const VerificationMeta('isPublic');
  @override
  late final GeneratedColumn<bool> isPublic = GeneratedColumn<bool>(
      'is_public', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_public" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncedEverMeta =
      const VerificationMeta('syncedEver');
  @override
  late final GeneratedColumn<bool> syncedEver = GeneratedColumn<bool>(
      'synced_ever', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced_ever" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        remoteId,
        name,
        description,
        coverUrl,
        coverPicId,
        coverSource,
        isPublic,
        deleted,
        isSynced,
        syncedEver,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_playlists';
  @override
  VerificationContext validateIntegrity(Insertable<LocalPlaylist> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('cover_pic_id')) {
      context.handle(
          _coverPicIdMeta,
          coverPicId.isAcceptableOrUnknown(
              data['cover_pic_id']!, _coverPicIdMeta));
    }
    if (data.containsKey('cover_source')) {
      context.handle(
          _coverSourceMeta,
          coverSource.isAcceptableOrUnknown(
              data['cover_source']!, _coverSourceMeta));
    }
    if (data.containsKey('is_public')) {
      context.handle(_isPublicMeta,
          isPublic.isAcceptableOrUnknown(data['is_public']!, _isPublicMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('synced_ever')) {
      context.handle(
          _syncedEverMeta,
          syncedEver.isAcceptableOrUnknown(
              data['synced_ever']!, _syncedEverMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlaylist(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remote_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url'])!,
      coverPicId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_pic_id']),
      coverSource: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_source']),
      isPublic: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_public'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      syncedEver: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced_ever'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalPlaylistsTable createAlias(String alias) {
    return $LocalPlaylistsTable(attachedDatabase, alias);
  }
}

class LocalPlaylist extends DataClass implements Insertable<LocalPlaylist> {
  /// 本地歌单 ID（UUID，客户端生成）
  final String id;

  /// 服务端歌单 ID（POST /playlists 创建成功后回填，null 表示尚未同步）
  final int? remoteId;

  /// 歌单名称
  final String name;

  /// 歌单描述
  final String description;

  /// 封面 URL
  final String coverUrl;

  /// 封面来源歌曲 pic_id（为空时按 coverUrl 或占位图；非空则客户端实时解析封面）
  final String? coverPicId;

  /// 封面来源歌曲音源标识
  final String? coverSource;

  /// 是否公开可见
  final bool isPublic;

  /// soft delete 标记
  final bool deleted;

  /// 是否已同步到服务端
  final bool isSynced;

  /// 是否曾成功同步过
  final bool syncedEver;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;
  const LocalPlaylist(
      {required this.id,
      this.remoteId,
      required this.name,
      required this.description,
      required this.coverUrl,
      this.coverPicId,
      this.coverSource,
      required this.isPublic,
      required this.deleted,
      required this.isSynced,
      required this.syncedEver,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['cover_url'] = Variable<String>(coverUrl);
    if (!nullToAbsent || coverPicId != null) {
      map['cover_pic_id'] = Variable<String>(coverPicId);
    }
    if (!nullToAbsent || coverSource != null) {
      map['cover_source'] = Variable<String>(coverSource);
    }
    map['is_public'] = Variable<bool>(isPublic);
    map['deleted'] = Variable<bool>(deleted);
    map['is_synced'] = Variable<bool>(isSynced);
    map['synced_ever'] = Variable<bool>(syncedEver);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return LocalPlaylistsCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      name: Value(name),
      description: Value(description),
      coverUrl: Value(coverUrl),
      coverPicId: coverPicId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPicId),
      coverSource: coverSource == null && nullToAbsent
          ? const Value.absent()
          : Value(coverSource),
      isPublic: Value(isPublic),
      deleted: Value(deleted),
      isSynced: Value(isSynced),
      syncedEver: Value(syncedEver),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalPlaylist.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlaylist(
      id: serializer.fromJson<String>(json['id']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      coverUrl: serializer.fromJson<String>(json['coverUrl']),
      coverPicId: serializer.fromJson<String?>(json['coverPicId']),
      coverSource: serializer.fromJson<String?>(json['coverSource']),
      isPublic: serializer.fromJson<bool>(json['isPublic']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncedEver: serializer.fromJson<bool>(json['syncedEver']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'remoteId': serializer.toJson<int?>(remoteId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'coverUrl': serializer.toJson<String>(coverUrl),
      'coverPicId': serializer.toJson<String?>(coverPicId),
      'coverSource': serializer.toJson<String?>(coverSource),
      'isPublic': serializer.toJson<bool>(isPublic),
      'deleted': serializer.toJson<bool>(deleted),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncedEver': serializer.toJson<bool>(syncedEver),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalPlaylist copyWith(
          {String? id,
          Value<int?> remoteId = const Value.absent(),
          String? name,
          String? description,
          String? coverUrl,
          Value<String?> coverPicId = const Value.absent(),
          Value<String?> coverSource = const Value.absent(),
          bool? isPublic,
          bool? deleted,
          bool? isSynced,
          bool? syncedEver,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      LocalPlaylist(
        id: id ?? this.id,
        remoteId: remoteId.present ? remoteId.value : this.remoteId,
        name: name ?? this.name,
        description: description ?? this.description,
        coverUrl: coverUrl ?? this.coverUrl,
        coverPicId: coverPicId.present ? coverPicId.value : this.coverPicId,
        coverSource: coverSource.present ? coverSource.value : this.coverSource,
        isPublic: isPublic ?? this.isPublic,
        deleted: deleted ?? this.deleted,
        isSynced: isSynced ?? this.isSynced,
        syncedEver: syncedEver ?? this.syncedEver,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalPlaylist copyWithCompanion(LocalPlaylistsCompanion data) {
    return LocalPlaylist(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      coverPicId:
          data.coverPicId.present ? data.coverPicId.value : this.coverPicId,
      coverSource:
          data.coverSource.present ? data.coverSource.value : this.coverSource,
      isPublic: data.isPublic.present ? data.isPublic.value : this.isPublic,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      syncedEver:
          data.syncedEver.present ? data.syncedEver.value : this.syncedEver,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylist(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverPicId: $coverPicId, ')
          ..write('coverSource: $coverSource, ')
          ..write('isPublic: $isPublic, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncedEver: $syncedEver, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      remoteId,
      name,
      description,
      coverUrl,
      coverPicId,
      coverSource,
      isPublic,
      deleted,
      isSynced,
      syncedEver,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlaylist &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.description == this.description &&
          other.coverUrl == this.coverUrl &&
          other.coverPicId == this.coverPicId &&
          other.coverSource == this.coverSource &&
          other.isPublic == this.isPublic &&
          other.deleted == this.deleted &&
          other.isSynced == this.isSynced &&
          other.syncedEver == this.syncedEver &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalPlaylistsCompanion extends UpdateCompanion<LocalPlaylist> {
  final Value<String> id;
  final Value<int?> remoteId;
  final Value<String> name;
  final Value<String> description;
  final Value<String> coverUrl;
  final Value<String?> coverPicId;
  final Value<String?> coverSource;
  final Value<bool> isPublic;
  final Value<bool> deleted;
  final Value<bool> isSynced;
  final Value<bool> syncedEver;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalPlaylistsCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.coverPicId = const Value.absent(),
    this.coverSource = const Value.absent(),
    this.isPublic = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncedEver = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPlaylistsCompanion.insert({
    required String id,
    this.remoteId = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.coverPicId = const Value.absent(),
    this.coverSource = const Value.absent(),
    this.isPublic = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncedEver = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<LocalPlaylist> custom({
    Expression<String>? id,
    Expression<int>? remoteId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? coverUrl,
    Expression<String>? coverPicId,
    Expression<String>? coverSource,
    Expression<bool>? isPublic,
    Expression<bool>? deleted,
    Expression<bool>? isSynced,
    Expression<bool>? syncedEver,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (coverPicId != null) 'cover_pic_id': coverPicId,
      if (coverSource != null) 'cover_source': coverSource,
      if (isPublic != null) 'is_public': isPublic,
      if (deleted != null) 'deleted': deleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncedEver != null) 'synced_ever': syncedEver,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPlaylistsCompanion copyWith(
      {Value<String>? id,
      Value<int?>? remoteId,
      Value<String>? name,
      Value<String>? description,
      Value<String>? coverUrl,
      Value<String?>? coverPicId,
      Value<String?>? coverSource,
      Value<bool>? isPublic,
      Value<bool>? deleted,
      Value<bool>? isSynced,
      Value<bool>? syncedEver,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalPlaylistsCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      coverPicId: coverPicId ?? this.coverPicId,
      coverSource: coverSource ?? this.coverSource,
      isPublic: isPublic ?? this.isPublic,
      deleted: deleted ?? this.deleted,
      isSynced: isSynced ?? this.isSynced,
      syncedEver: syncedEver ?? this.syncedEver,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (coverPicId.present) {
      map['cover_pic_id'] = Variable<String>(coverPicId.value);
    }
    if (coverSource.present) {
      map['cover_source'] = Variable<String>(coverSource.value);
    }
    if (isPublic.present) {
      map['is_public'] = Variable<bool>(isPublic.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncedEver.present) {
      map['synced_ever'] = Variable<bool>(syncedEver.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverPicId: $coverPicId, ')
          ..write('coverSource: $coverSource, ')
          ..write('isPublic: $isPublic, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncedEver: $syncedEver, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPlaylistSongsTable extends LocalPlaylistSongs
    with TableInfo<$LocalPlaylistSongsTable, LocalPlaylistSong> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlaylistSongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playlistIdMeta =
      const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
      'playlist_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_playlists (id)'));
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
      'song_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _songNameMeta =
      const VerificationMeta('songName');
  @override
  late final GeneratedColumn<String> songName = GeneratedColumn<String>(
      'song_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
      'artist', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
      'album', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _picIdMeta = const VerificationMeta('picId');
  @override
  late final GeneratedColumn<String> picId = GeneratedColumn<String>(
      'pic_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lyricIdMeta =
      const VerificationMeta('lyricId');
  @override
  late final GeneratedColumn<String> lyricId = GeneratedColumn<String>(
      'lyric_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
      'remote_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncedEverMeta =
      const VerificationMeta('syncedEver');
  @override
  late final GeneratedColumn<bool> syncedEver = GeneratedColumn<bool>(
      'synced_ever', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced_ever" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        playlistId,
        songId,
        source,
        songName,
        artist,
        album,
        coverUrl,
        picId,
        lyricId,
        sortOrder,
        remoteId,
        deleted,
        isSynced,
        syncedEver,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_playlist_songs';
  @override
  VerificationContext validateIntegrity(Insertable<LocalPlaylistSong> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
          _playlistIdMeta,
          playlistId.isAcceptableOrUnknown(
              data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('song_id')) {
      context.handle(_songIdMeta,
          songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta));
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('song_name')) {
      context.handle(_songNameMeta,
          songName.isAcceptableOrUnknown(data['song_name']!, _songNameMeta));
    } else if (isInserting) {
      context.missing(_songNameMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(_artistMeta,
          artist.isAcceptableOrUnknown(data['artist']!, _artistMeta));
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('album')) {
      context.handle(
          _albumMeta, album.isAcceptableOrUnknown(data['album']!, _albumMeta));
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('pic_id')) {
      context.handle(
          _picIdMeta, picId.isAcceptableOrUnknown(data['pic_id']!, _picIdMeta));
    }
    if (data.containsKey('lyric_id')) {
      context.handle(_lyricIdMeta,
          lyricId.isAcceptableOrUnknown(data['lyric_id']!, _lyricIdMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('synced_ever')) {
      context.handle(
          _syncedEverMeta,
          syncedEver.isAcceptableOrUnknown(
              data['synced_ever']!, _syncedEverMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {playlistId, songId, source},
      ];
  @override
  LocalPlaylistSong map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlaylistSong(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playlistId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}playlist_id'])!,
      songId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      songName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song_name'])!,
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist'])!,
      album: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album'])!,
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url']),
      picId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pic_id']),
      lyricId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lyric_id']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remote_id']),
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      syncedEver: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced_ever'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LocalPlaylistSongsTable createAlias(String alias) {
    return $LocalPlaylistSongsTable(attachedDatabase, alias);
  }
}

class LocalPlaylistSong extends DataClass
    implements Insertable<LocalPlaylistSong> {
  /// 本地行主键（自增）
  final int id;

  /// 所属本地歌单 ID（FK → local_playlists.id）
  final String playlistId;

  /// 歌曲 ID
  final String songId;

  /// 音源
  final String source;

  /// 歌曲名
  final String songName;

  /// 歌手
  final String artist;

  /// 专辑
  final String album;

  /// 封面 URL
  final String? coverUrl;

  /// 封面图 pic_id
  final String? picId;

  /// 歌词 ID（音源原始歌词 ID，实时解析歌词）
  final String? lyricId;

  /// 本地排序序号
  final int sortOrder;

  /// 远端 playlist_songs 记录 id（同步后回填，reorder 增强用）
  final int? remoteId;

  /// soft delete 标记
  final bool deleted;

  /// 是否已同步到服务端
  final bool isSynced;

  /// 是否曾成功同步过
  final bool syncedEver;

  /// 创建时间
  final DateTime createdAt;
  const LocalPlaylistSong(
      {required this.id,
      required this.playlistId,
      required this.songId,
      required this.source,
      required this.songName,
      required this.artist,
      required this.album,
      this.coverUrl,
      this.picId,
      this.lyricId,
      required this.sortOrder,
      this.remoteId,
      required this.deleted,
      required this.isSynced,
      required this.syncedEver,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['song_id'] = Variable<String>(songId);
    map['source'] = Variable<String>(source);
    map['song_name'] = Variable<String>(songName);
    map['artist'] = Variable<String>(artist);
    map['album'] = Variable<String>(album);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || picId != null) {
      map['pic_id'] = Variable<String>(picId);
    }
    if (!nullToAbsent || lyricId != null) {
      map['lyric_id'] = Variable<String>(lyricId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    map['deleted'] = Variable<bool>(deleted);
    map['is_synced'] = Variable<bool>(isSynced);
    map['synced_ever'] = Variable<bool>(syncedEver);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalPlaylistSongsCompanion toCompanion(bool nullToAbsent) {
    return LocalPlaylistSongsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      songId: Value(songId),
      source: Value(source),
      songName: Value(songName),
      artist: Value(artist),
      album: Value(album),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      picId:
          picId == null && nullToAbsent ? const Value.absent() : Value(picId),
      lyricId: lyricId == null && nullToAbsent
          ? const Value.absent()
          : Value(lyricId),
      sortOrder: Value(sortOrder),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      deleted: Value(deleted),
      isSynced: Value(isSynced),
      syncedEver: Value(syncedEver),
      createdAt: Value(createdAt),
    );
  }

  factory LocalPlaylistSong.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlaylistSong(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      songId: serializer.fromJson<String>(json['songId']),
      source: serializer.fromJson<String>(json['source']),
      songName: serializer.fromJson<String>(json['songName']),
      artist: serializer.fromJson<String>(json['artist']),
      album: serializer.fromJson<String>(json['album']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      picId: serializer.fromJson<String?>(json['picId']),
      lyricId: serializer.fromJson<String?>(json['lyricId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncedEver: serializer.fromJson<bool>(json['syncedEver']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'songId': serializer.toJson<String>(songId),
      'source': serializer.toJson<String>(source),
      'songName': serializer.toJson<String>(songName),
      'artist': serializer.toJson<String>(artist),
      'album': serializer.toJson<String>(album),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'picId': serializer.toJson<String?>(picId),
      'lyricId': serializer.toJson<String?>(lyricId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'remoteId': serializer.toJson<int?>(remoteId),
      'deleted': serializer.toJson<bool>(deleted),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncedEver': serializer.toJson<bool>(syncedEver),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalPlaylistSong copyWith(
          {int? id,
          String? playlistId,
          String? songId,
          String? source,
          String? songName,
          String? artist,
          String? album,
          Value<String?> coverUrl = const Value.absent(),
          Value<String?> picId = const Value.absent(),
          Value<String?> lyricId = const Value.absent(),
          int? sortOrder,
          Value<int?> remoteId = const Value.absent(),
          bool? deleted,
          bool? isSynced,
          bool? syncedEver,
          DateTime? createdAt}) =>
      LocalPlaylistSong(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        songId: songId ?? this.songId,
        source: source ?? this.source,
        songName: songName ?? this.songName,
        artist: artist ?? this.artist,
        album: album ?? this.album,
        coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
        picId: picId.present ? picId.value : this.picId,
        lyricId: lyricId.present ? lyricId.value : this.lyricId,
        sortOrder: sortOrder ?? this.sortOrder,
        remoteId: remoteId.present ? remoteId.value : this.remoteId,
        deleted: deleted ?? this.deleted,
        isSynced: isSynced ?? this.isSynced,
        syncedEver: syncedEver ?? this.syncedEver,
        createdAt: createdAt ?? this.createdAt,
      );
  LocalPlaylistSong copyWithCompanion(LocalPlaylistSongsCompanion data) {
    return LocalPlaylistSong(
      id: data.id.present ? data.id.value : this.id,
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      songId: data.songId.present ? data.songId.value : this.songId,
      source: data.source.present ? data.source.value : this.source,
      songName: data.songName.present ? data.songName.value : this.songName,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      picId: data.picId.present ? data.picId.value : this.picId,
      lyricId: data.lyricId.present ? data.lyricId.value : this.lyricId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      syncedEver:
          data.syncedEver.present ? data.syncedEver.value : this.syncedEver,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylistSong(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('songId: $songId, ')
          ..write('source: $source, ')
          ..write('songName: $songName, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('picId: $picId, ')
          ..write('lyricId: $lyricId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('remoteId: $remoteId, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncedEver: $syncedEver, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      playlistId,
      songId,
      source,
      songName,
      artist,
      album,
      coverUrl,
      picId,
      lyricId,
      sortOrder,
      remoteId,
      deleted,
      isSynced,
      syncedEver,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlaylistSong &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.songId == this.songId &&
          other.source == this.source &&
          other.songName == this.songName &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.coverUrl == this.coverUrl &&
          other.picId == this.picId &&
          other.lyricId == this.lyricId &&
          other.sortOrder == this.sortOrder &&
          other.remoteId == this.remoteId &&
          other.deleted == this.deleted &&
          other.isSynced == this.isSynced &&
          other.syncedEver == this.syncedEver &&
          other.createdAt == this.createdAt);
}

class LocalPlaylistSongsCompanion extends UpdateCompanion<LocalPlaylistSong> {
  final Value<int> id;
  final Value<String> playlistId;
  final Value<String> songId;
  final Value<String> source;
  final Value<String> songName;
  final Value<String> artist;
  final Value<String> album;
  final Value<String?> coverUrl;
  final Value<String?> picId;
  final Value<String?> lyricId;
  final Value<int> sortOrder;
  final Value<int?> remoteId;
  final Value<bool> deleted;
  final Value<bool> isSynced;
  final Value<bool> syncedEver;
  final Value<DateTime> createdAt;
  const LocalPlaylistSongsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.songId = const Value.absent(),
    this.source = const Value.absent(),
    this.songName = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.picId = const Value.absent(),
    this.lyricId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncedEver = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalPlaylistSongsCompanion.insert({
    this.id = const Value.absent(),
    required String playlistId,
    required String songId,
    required String source,
    required String songName,
    required String artist,
    this.album = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.picId = const Value.absent(),
    this.lyricId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncedEver = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : playlistId = Value(playlistId),
        songId = Value(songId),
        source = Value(source),
        songName = Value(songName),
        artist = Value(artist);
  static Insertable<LocalPlaylistSong> custom({
    Expression<int>? id,
    Expression<String>? playlistId,
    Expression<String>? songId,
    Expression<String>? source,
    Expression<String>? songName,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<String>? coverUrl,
    Expression<String>? picId,
    Expression<String>? lyricId,
    Expression<int>? sortOrder,
    Expression<int>? remoteId,
    Expression<bool>? deleted,
    Expression<bool>? isSynced,
    Expression<bool>? syncedEver,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (songId != null) 'song_id': songId,
      if (source != null) 'source': source,
      if (songName != null) 'song_name': songName,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (picId != null) 'pic_id': picId,
      if (lyricId != null) 'lyric_id': lyricId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (remoteId != null) 'remote_id': remoteId,
      if (deleted != null) 'deleted': deleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncedEver != null) 'synced_ever': syncedEver,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalPlaylistSongsCompanion copyWith(
      {Value<int>? id,
      Value<String>? playlistId,
      Value<String>? songId,
      Value<String>? source,
      Value<String>? songName,
      Value<String>? artist,
      Value<String>? album,
      Value<String?>? coverUrl,
      Value<String?>? picId,
      Value<String?>? lyricId,
      Value<int>? sortOrder,
      Value<int?>? remoteId,
      Value<bool>? deleted,
      Value<bool>? isSynced,
      Value<bool>? syncedEver,
      Value<DateTime>? createdAt}) {
    return LocalPlaylistSongsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      songId: songId ?? this.songId,
      source: source ?? this.source,
      songName: songName ?? this.songName,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverUrl: coverUrl ?? this.coverUrl,
      picId: picId ?? this.picId,
      lyricId: lyricId ?? this.lyricId,
      sortOrder: sortOrder ?? this.sortOrder,
      remoteId: remoteId ?? this.remoteId,
      deleted: deleted ?? this.deleted,
      isSynced: isSynced ?? this.isSynced,
      syncedEver: syncedEver ?? this.syncedEver,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (songName.present) {
      map['song_name'] = Variable<String>(songName.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (picId.present) {
      map['pic_id'] = Variable<String>(picId.value);
    }
    if (lyricId.present) {
      map['lyric_id'] = Variable<String>(lyricId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncedEver.present) {
      map['synced_ever'] = Variable<bool>(syncedEver.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylistSongsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('songId: $songId, ')
          ..write('source: $source, ')
          ..write('songName: $songName, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('picId: $picId, ')
          ..write('lyricId: $lyricId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('remoteId: $remoteId, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncedEver: $syncedEver, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LocalPlayRecordsTable extends LocalPlayRecords
    with TableInfo<$LocalPlayRecordsTable, LocalPlayRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlayRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
      'song_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _songNameMeta =
      const VerificationMeta('songName');
  @override
  late final GeneratedColumn<String> songName = GeneratedColumn<String>(
      'song_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
      'artist', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _picIdMeta = const VerificationMeta('picId');
  @override
  late final GeneratedColumn<String> picId = GeneratedColumn<String>(
      'pic_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
      'album', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _lyricIdMeta =
      const VerificationMeta('lyricId');
  @override
  late final GeneratedColumn<String> lyricId = GeneratedColumn<String>(
      'lyric_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _playedAtMeta =
      const VerificationMeta('playedAt');
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
      'played_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        songId,
        source,
        songName,
        artist,
        coverUrl,
        picId,
        album,
        lyricId,
        playedAt,
        isSynced,
        attemptCount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_play_records';
  @override
  VerificationContext validateIntegrity(Insertable<LocalPlayRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('song_id')) {
      context.handle(_songIdMeta,
          songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta));
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('song_name')) {
      context.handle(_songNameMeta,
          songName.isAcceptableOrUnknown(data['song_name']!, _songNameMeta));
    }
    if (data.containsKey('artist')) {
      context.handle(_artistMeta,
          artist.isAcceptableOrUnknown(data['artist']!, _artistMeta));
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('pic_id')) {
      context.handle(
          _picIdMeta, picId.isAcceptableOrUnknown(data['pic_id']!, _picIdMeta));
    }
    if (data.containsKey('album')) {
      context.handle(
          _albumMeta, album.isAcceptableOrUnknown(data['album']!, _albumMeta));
    }
    if (data.containsKey('lyric_id')) {
      context.handle(_lyricIdMeta,
          lyricId.isAcceptableOrUnknown(data['lyric_id']!, _lyricIdMeta));
    }
    if (data.containsKey('played_at')) {
      context.handle(_playedAtMeta,
          playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPlayRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlayRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      songId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      songName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song_name'])!,
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist'])!,
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url']),
      picId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pic_id']),
      album: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album'])!,
      lyricId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lyric_id']),
      playedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}played_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
    );
  }

  @override
  $LocalPlayRecordsTable createAlias(String alias) {
    return $LocalPlayRecordsTable(attachedDatabase, alias);
  }
}

class LocalPlayRecord extends DataClass implements Insertable<LocalPlayRecord> {
  /// 本地行主键（自增）
  final int id;

  /// 歌曲 ID
  final String songId;

  /// 音源
  final String source;

  /// 歌曲名
  final String songName;

  /// 歌手
  final String artist;

  /// 封面 URL
  final String? coverUrl;

  /// 封面图 pic_id（音源原始封面 ID，实时解析封面）
  final String? picId;

  /// 专辑
  final String album;

  /// 歌词 ID（音源原始歌词 ID，实时解析歌词）
  final String? lyricId;

  /// 播放时间（本地记录时刻）
  final DateTime playedAt;

  /// 是否已同步到服务端
  final bool isSynced;

  /// 同步尝试次数（超过上限暂停，避免断网重试重复计数）
  final int attemptCount;
  const LocalPlayRecord(
      {required this.id,
      required this.songId,
      required this.source,
      required this.songName,
      required this.artist,
      this.coverUrl,
      this.picId,
      required this.album,
      this.lyricId,
      required this.playedAt,
      required this.isSynced,
      required this.attemptCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['song_id'] = Variable<String>(songId);
    map['source'] = Variable<String>(source);
    map['song_name'] = Variable<String>(songName);
    map['artist'] = Variable<String>(artist);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || picId != null) {
      map['pic_id'] = Variable<String>(picId);
    }
    map['album'] = Variable<String>(album);
    if (!nullToAbsent || lyricId != null) {
      map['lyric_id'] = Variable<String>(lyricId);
    }
    map['played_at'] = Variable<DateTime>(playedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    map['attempt_count'] = Variable<int>(attemptCount);
    return map;
  }

  LocalPlayRecordsCompanion toCompanion(bool nullToAbsent) {
    return LocalPlayRecordsCompanion(
      id: Value(id),
      songId: Value(songId),
      source: Value(source),
      songName: Value(songName),
      artist: Value(artist),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      picId:
          picId == null && nullToAbsent ? const Value.absent() : Value(picId),
      album: Value(album),
      lyricId: lyricId == null && nullToAbsent
          ? const Value.absent()
          : Value(lyricId),
      playedAt: Value(playedAt),
      isSynced: Value(isSynced),
      attemptCount: Value(attemptCount),
    );
  }

  factory LocalPlayRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlayRecord(
      id: serializer.fromJson<int>(json['id']),
      songId: serializer.fromJson<String>(json['songId']),
      source: serializer.fromJson<String>(json['source']),
      songName: serializer.fromJson<String>(json['songName']),
      artist: serializer.fromJson<String>(json['artist']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      picId: serializer.fromJson<String?>(json['picId']),
      album: serializer.fromJson<String>(json['album']),
      lyricId: serializer.fromJson<String?>(json['lyricId']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'songId': serializer.toJson<String>(songId),
      'source': serializer.toJson<String>(source),
      'songName': serializer.toJson<String>(songName),
      'artist': serializer.toJson<String>(artist),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'picId': serializer.toJson<String?>(picId),
      'album': serializer.toJson<String>(album),
      'lyricId': serializer.toJson<String?>(lyricId),
      'playedAt': serializer.toJson<DateTime>(playedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'attemptCount': serializer.toJson<int>(attemptCount),
    };
  }

  LocalPlayRecord copyWith(
          {int? id,
          String? songId,
          String? source,
          String? songName,
          String? artist,
          Value<String?> coverUrl = const Value.absent(),
          Value<String?> picId = const Value.absent(),
          String? album,
          Value<String?> lyricId = const Value.absent(),
          DateTime? playedAt,
          bool? isSynced,
          int? attemptCount}) =>
      LocalPlayRecord(
        id: id ?? this.id,
        songId: songId ?? this.songId,
        source: source ?? this.source,
        songName: songName ?? this.songName,
        artist: artist ?? this.artist,
        coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
        picId: picId.present ? picId.value : this.picId,
        album: album ?? this.album,
        lyricId: lyricId.present ? lyricId.value : this.lyricId,
        playedAt: playedAt ?? this.playedAt,
        isSynced: isSynced ?? this.isSynced,
        attemptCount: attemptCount ?? this.attemptCount,
      );
  LocalPlayRecord copyWithCompanion(LocalPlayRecordsCompanion data) {
    return LocalPlayRecord(
      id: data.id.present ? data.id.value : this.id,
      songId: data.songId.present ? data.songId.value : this.songId,
      source: data.source.present ? data.source.value : this.source,
      songName: data.songName.present ? data.songName.value : this.songName,
      artist: data.artist.present ? data.artist.value : this.artist,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      picId: data.picId.present ? data.picId.value : this.picId,
      album: data.album.present ? data.album.value : this.album,
      lyricId: data.lyricId.present ? data.lyricId.value : this.lyricId,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlayRecord(')
          ..write('id: $id, ')
          ..write('songId: $songId, ')
          ..write('source: $source, ')
          ..write('songName: $songName, ')
          ..write('artist: $artist, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('picId: $picId, ')
          ..write('album: $album, ')
          ..write('lyricId: $lyricId, ')
          ..write('playedAt: $playedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('attemptCount: $attemptCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, songId, source, songName, artist,
      coverUrl, picId, album, lyricId, playedAt, isSynced, attemptCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlayRecord &&
          other.id == this.id &&
          other.songId == this.songId &&
          other.source == this.source &&
          other.songName == this.songName &&
          other.artist == this.artist &&
          other.coverUrl == this.coverUrl &&
          other.picId == this.picId &&
          other.album == this.album &&
          other.lyricId == this.lyricId &&
          other.playedAt == this.playedAt &&
          other.isSynced == this.isSynced &&
          other.attemptCount == this.attemptCount);
}

class LocalPlayRecordsCompanion extends UpdateCompanion<LocalPlayRecord> {
  final Value<int> id;
  final Value<String> songId;
  final Value<String> source;
  final Value<String> songName;
  final Value<String> artist;
  final Value<String?> coverUrl;
  final Value<String?> picId;
  final Value<String> album;
  final Value<String?> lyricId;
  final Value<DateTime> playedAt;
  final Value<bool> isSynced;
  final Value<int> attemptCount;
  const LocalPlayRecordsCompanion({
    this.id = const Value.absent(),
    this.songId = const Value.absent(),
    this.source = const Value.absent(),
    this.songName = const Value.absent(),
    this.artist = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.picId = const Value.absent(),
    this.album = const Value.absent(),
    this.lyricId = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.attemptCount = const Value.absent(),
  });
  LocalPlayRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String songId,
    this.source = const Value.absent(),
    this.songName = const Value.absent(),
    this.artist = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.picId = const Value.absent(),
    this.album = const Value.absent(),
    this.lyricId = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.attemptCount = const Value.absent(),
  }) : songId = Value(songId);
  static Insertable<LocalPlayRecord> custom({
    Expression<int>? id,
    Expression<String>? songId,
    Expression<String>? source,
    Expression<String>? songName,
    Expression<String>? artist,
    Expression<String>? coverUrl,
    Expression<String>? picId,
    Expression<String>? album,
    Expression<String>? lyricId,
    Expression<DateTime>? playedAt,
    Expression<bool>? isSynced,
    Expression<int>? attemptCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (songId != null) 'song_id': songId,
      if (source != null) 'source': source,
      if (songName != null) 'song_name': songName,
      if (artist != null) 'artist': artist,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (picId != null) 'pic_id': picId,
      if (album != null) 'album': album,
      if (lyricId != null) 'lyric_id': lyricId,
      if (playedAt != null) 'played_at': playedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (attemptCount != null) 'attempt_count': attemptCount,
    });
  }

  LocalPlayRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? songId,
      Value<String>? source,
      Value<String>? songName,
      Value<String>? artist,
      Value<String?>? coverUrl,
      Value<String?>? picId,
      Value<String>? album,
      Value<String?>? lyricId,
      Value<DateTime>? playedAt,
      Value<bool>? isSynced,
      Value<int>? attemptCount}) {
    return LocalPlayRecordsCompanion(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      source: source ?? this.source,
      songName: songName ?? this.songName,
      artist: artist ?? this.artist,
      coverUrl: coverUrl ?? this.coverUrl,
      picId: picId ?? this.picId,
      album: album ?? this.album,
      lyricId: lyricId ?? this.lyricId,
      playedAt: playedAt ?? this.playedAt,
      isSynced: isSynced ?? this.isSynced,
      attemptCount: attemptCount ?? this.attemptCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (songName.present) {
      map['song_name'] = Variable<String>(songName.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (picId.present) {
      map['pic_id'] = Variable<String>(picId.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (lyricId.present) {
      map['lyric_id'] = Variable<String>(lyricId.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlayRecordsCompanion(')
          ..write('id: $id, ')
          ..write('songId: $songId, ')
          ..write('source: $source, ')
          ..write('songName: $songName, ')
          ..write('artist: $artist, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('picId: $picId, ')
          ..write('album: $album, ')
          ..write('lyricId: $lyricId, ')
          ..write('playedAt: $playedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('attemptCount: $attemptCount')
          ..write(')'))
        .toString();
  }
}

class $LocalSearchHistoryTable extends LocalSearchHistory
    with TableInfo<$LocalSearchHistoryTable, LocalSearchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSearchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _keywordMeta =
      const VerificationMeta('keyword');
  @override
  late final GeneratedColumn<String> keyword = GeneratedColumn<String>(
      'keyword', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, keyword, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_search_history';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalSearchHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('keyword')) {
      context.handle(_keywordMeta,
          keyword.isAcceptableOrUnknown(data['keyword']!, _keywordMeta));
    } else if (isInserting) {
      context.missing(_keywordMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSearchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSearchHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      keyword: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}keyword'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LocalSearchHistoryTable createAlias(String alias) {
    return $LocalSearchHistoryTable(attachedDatabase, alias);
  }
}

class LocalSearchHistoryData extends DataClass
    implements Insertable<LocalSearchHistoryData> {
  /// 本地行主键（自增）
  final int id;

  /// 搜索关键词（唯一，去重置顶）
  final String keyword;

  /// 搜索时间
  final DateTime createdAt;
  const LocalSearchHistoryData(
      {required this.id, required this.keyword, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['keyword'] = Variable<String>(keyword);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalSearchHistoryCompanion toCompanion(bool nullToAbsent) {
    return LocalSearchHistoryCompanion(
      id: Value(id),
      keyword: Value(keyword),
      createdAt: Value(createdAt),
    );
  }

  factory LocalSearchHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSearchHistoryData(
      id: serializer.fromJson<int>(json['id']),
      keyword: serializer.fromJson<String>(json['keyword']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'keyword': serializer.toJson<String>(keyword),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalSearchHistoryData copyWith(
          {int? id, String? keyword, DateTime? createdAt}) =>
      LocalSearchHistoryData(
        id: id ?? this.id,
        keyword: keyword ?? this.keyword,
        createdAt: createdAt ?? this.createdAt,
      );
  LocalSearchHistoryData copyWithCompanion(LocalSearchHistoryCompanion data) {
    return LocalSearchHistoryData(
      id: data.id.present ? data.id.value : this.id,
      keyword: data.keyword.present ? data.keyword.value : this.keyword,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSearchHistoryData(')
          ..write('id: $id, ')
          ..write('keyword: $keyword, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, keyword, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSearchHistoryData &&
          other.id == this.id &&
          other.keyword == this.keyword &&
          other.createdAt == this.createdAt);
}

class LocalSearchHistoryCompanion
    extends UpdateCompanion<LocalSearchHistoryData> {
  final Value<int> id;
  final Value<String> keyword;
  final Value<DateTime> createdAt;
  const LocalSearchHistoryCompanion({
    this.id = const Value.absent(),
    this.keyword = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalSearchHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String keyword,
    this.createdAt = const Value.absent(),
  }) : keyword = Value(keyword);
  static Insertable<LocalSearchHistoryData> custom({
    Expression<int>? id,
    Expression<String>? keyword,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (keyword != null) 'keyword': keyword,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalSearchHistoryCompanion copyWith(
      {Value<int>? id, Value<String>? keyword, Value<DateTime>? createdAt}) {
    return LocalSearchHistoryCompanion(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (keyword.present) {
      map['keyword'] = Variable<String>(keyword.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSearchHistoryCompanion(')
          ..write('id: $id, ')
          ..write('keyword: $keyword, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LocalPlaySessionsTable extends LocalPlaySessions
    with TableInfo<$LocalPlaySessionsTable, LocalPlaySession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlaySessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _queueJsonMeta =
      const VerificationMeta('queueJson');
  @override
  late final GeneratedColumn<String> queueJson = GeneratedColumn<String>(
      'queue_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currentIndexMeta =
      const VerificationMeta('currentIndex');
  @override
  late final GeneratedColumn<int> currentIndex = GeneratedColumn<int>(
      'current_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _positionMsMeta =
      const VerificationMeta('positionMs');
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
      'position_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _playModeMeta =
      const VerificationMeta('playMode');
  @override
  late final GeneratedColumn<String> playMode = GeneratedColumn<String>(
      'play_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('loop'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, queueJson, currentIndex, positionMs, playMode, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_play_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<LocalPlaySession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('queue_json')) {
      context.handle(_queueJsonMeta,
          queueJson.isAcceptableOrUnknown(data['queue_json']!, _queueJsonMeta));
    }
    if (data.containsKey('current_index')) {
      context.handle(
          _currentIndexMeta,
          currentIndex.isAcceptableOrUnknown(
              data['current_index']!, _currentIndexMeta));
    }
    if (data.containsKey('position_ms')) {
      context.handle(
          _positionMsMeta,
          positionMs.isAcceptableOrUnknown(
              data['position_ms']!, _positionMsMeta));
    }
    if (data.containsKey('play_mode')) {
      context.handle(_playModeMeta,
          playMode.isAcceptableOrUnknown(data['play_mode']!, _playModeMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPlaySession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlaySession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      queueJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}queue_json']),
      currentIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_index'])!,
      positionMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position_ms'])!,
      playMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}play_mode'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalPlaySessionsTable createAlias(String alias) {
    return $LocalPlaySessionsTable(attachedDatabase, alias);
  }
}

class LocalPlaySession extends DataClass
    implements Insertable<LocalPlaySession> {
  /// 单行固定 id=1
  final int id;

  /// 播放队列（歌曲 JSON 序列化，沿用现有队列模型）
  final String? queueJson;

  /// 当前播放索引
  final int currentIndex;

  /// 播放进度（毫秒）
  final int positionMs;

  /// 播放模式（sequential/loop/shuffle）
  final String playMode;

  /// 更新时间
  final DateTime updatedAt;
  const LocalPlaySession(
      {required this.id,
      this.queueJson,
      required this.currentIndex,
      required this.positionMs,
      required this.playMode,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || queueJson != null) {
      map['queue_json'] = Variable<String>(queueJson);
    }
    map['current_index'] = Variable<int>(currentIndex);
    map['position_ms'] = Variable<int>(positionMs);
    map['play_mode'] = Variable<String>(playMode);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalPlaySessionsCompanion toCompanion(bool nullToAbsent) {
    return LocalPlaySessionsCompanion(
      id: Value(id),
      queueJson: queueJson == null && nullToAbsent
          ? const Value.absent()
          : Value(queueJson),
      currentIndex: Value(currentIndex),
      positionMs: Value(positionMs),
      playMode: Value(playMode),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalPlaySession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlaySession(
      id: serializer.fromJson<int>(json['id']),
      queueJson: serializer.fromJson<String?>(json['queueJson']),
      currentIndex: serializer.fromJson<int>(json['currentIndex']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      playMode: serializer.fromJson<String>(json['playMode']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'queueJson': serializer.toJson<String?>(queueJson),
      'currentIndex': serializer.toJson<int>(currentIndex),
      'positionMs': serializer.toJson<int>(positionMs),
      'playMode': serializer.toJson<String>(playMode),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalPlaySession copyWith(
          {int? id,
          Value<String?> queueJson = const Value.absent(),
          int? currentIndex,
          int? positionMs,
          String? playMode,
          DateTime? updatedAt}) =>
      LocalPlaySession(
        id: id ?? this.id,
        queueJson: queueJson.present ? queueJson.value : this.queueJson,
        currentIndex: currentIndex ?? this.currentIndex,
        positionMs: positionMs ?? this.positionMs,
        playMode: playMode ?? this.playMode,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalPlaySession copyWithCompanion(LocalPlaySessionsCompanion data) {
    return LocalPlaySession(
      id: data.id.present ? data.id.value : this.id,
      queueJson: data.queueJson.present ? data.queueJson.value : this.queueJson,
      currentIndex: data.currentIndex.present
          ? data.currentIndex.value
          : this.currentIndex,
      positionMs:
          data.positionMs.present ? data.positionMs.value : this.positionMs,
      playMode: data.playMode.present ? data.playMode.value : this.playMode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaySession(')
          ..write('id: $id, ')
          ..write('queueJson: $queueJson, ')
          ..write('currentIndex: $currentIndex, ')
          ..write('positionMs: $positionMs, ')
          ..write('playMode: $playMode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, queueJson, currentIndex, positionMs, playMode, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlaySession &&
          other.id == this.id &&
          other.queueJson == this.queueJson &&
          other.currentIndex == this.currentIndex &&
          other.positionMs == this.positionMs &&
          other.playMode == this.playMode &&
          other.updatedAt == this.updatedAt);
}

class LocalPlaySessionsCompanion extends UpdateCompanion<LocalPlaySession> {
  final Value<int> id;
  final Value<String?> queueJson;
  final Value<int> currentIndex;
  final Value<int> positionMs;
  final Value<String> playMode;
  final Value<DateTime> updatedAt;
  const LocalPlaySessionsCompanion({
    this.id = const Value.absent(),
    this.queueJson = const Value.absent(),
    this.currentIndex = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.playMode = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalPlaySessionsCompanion.insert({
    this.id = const Value.absent(),
    this.queueJson = const Value.absent(),
    this.currentIndex = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.playMode = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<LocalPlaySession> custom({
    Expression<int>? id,
    Expression<String>? queueJson,
    Expression<int>? currentIndex,
    Expression<int>? positionMs,
    Expression<String>? playMode,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (queueJson != null) 'queue_json': queueJson,
      if (currentIndex != null) 'current_index': currentIndex,
      if (positionMs != null) 'position_ms': positionMs,
      if (playMode != null) 'play_mode': playMode,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalPlaySessionsCompanion copyWith(
      {Value<int>? id,
      Value<String?>? queueJson,
      Value<int>? currentIndex,
      Value<int>? positionMs,
      Value<String>? playMode,
      Value<DateTime>? updatedAt}) {
    return LocalPlaySessionsCompanion(
      id: id ?? this.id,
      queueJson: queueJson ?? this.queueJson,
      currentIndex: currentIndex ?? this.currentIndex,
      positionMs: positionMs ?? this.positionMs,
      playMode: playMode ?? this.playMode,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (currentIndex.present) {
      map['current_index'] = Variable<int>(currentIndex.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (playMode.present) {
      map['play_mode'] = Variable<String>(playMode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaySessionsCompanion(')
          ..write('id: $id, ')
          ..write('queueJson: $queueJson, ')
          ..write('currentIndex: $currentIndex, ')
          ..write('positionMs: $positionMs, ')
          ..write('playMode: $playMode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalSettingsTable extends LocalSettings
    with TableInfo<$LocalSettingsTable, LocalSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(Insertable<LocalSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }
}

class LocalSetting extends DataClass implements Insertable<LocalSetting> {
  /// 配置键名
  final String key;

  /// 配置值
  final String value;
  const LocalSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory LocalSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSetting(
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

  LocalSetting copyWith({String? key, String? value}) => LocalSetting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  LocalSetting copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetting(')
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
      (other is LocalSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<LocalSetting> custom({
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

  LocalSettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return LocalSettingsCompanion(
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
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSongMetaTable extends LocalSongMeta
    with TableInfo<$LocalSongMetaTable, LocalSongMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSongMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
      'song_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
      'artist', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
      'album', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _picIdMeta = const VerificationMeta('picId');
  @override
  late final GeneratedColumn<String> picId = GeneratedColumn<String>(
      'pic_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lyricIdMeta =
      const VerificationMeta('lyricId');
  @override
  late final GeneratedColumn<String> lyricId = GeneratedColumn<String>(
      'lyric_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lyricsMeta = const VerificationMeta('lyrics');
  @override
  late final GeneratedColumn<String> lyrics = GeneratedColumn<String>(
      'lyrics', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        songId,
        source,
        name,
        artist,
        album,
        picId,
        lyricId,
        coverUrl,
        lyrics,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_song_meta';
  @override
  VerificationContext validateIntegrity(Insertable<LocalSongMetaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('song_id')) {
      context.handle(_songIdMeta,
          songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta));
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('artist')) {
      context.handle(_artistMeta,
          artist.isAcceptableOrUnknown(data['artist']!, _artistMeta));
    }
    if (data.containsKey('album')) {
      context.handle(
          _albumMeta, album.isAcceptableOrUnknown(data['album']!, _albumMeta));
    }
    if (data.containsKey('pic_id')) {
      context.handle(
          _picIdMeta, picId.isAcceptableOrUnknown(data['pic_id']!, _picIdMeta));
    }
    if (data.containsKey('lyric_id')) {
      context.handle(_lyricIdMeta,
          lyricId.isAcceptableOrUnknown(data['lyric_id']!, _lyricIdMeta));
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('lyrics')) {
      context.handle(_lyricsMeta,
          lyrics.isAcceptableOrUnknown(data['lyrics']!, _lyricsMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {songId, source};
  @override
  LocalSongMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSongMetaData(
      songId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist'])!,
      album: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album'])!,
      picId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pic_id']),
      lyricId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lyric_id']),
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url']),
      lyrics: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lyrics']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalSongMetaTable createAlias(String alias) {
    return $LocalSongMetaTable(attachedDatabase, alias);
  }
}

class LocalSongMetaData extends DataClass
    implements Insertable<LocalSongMetaData> {
  /// 歌曲 ID（原始音源 ID）
  final String songId;

  /// 音源标识
  final String source;

  /// 歌曲名
  final String name;

  /// 歌手
  final String artist;

  /// 专辑
  final String album;

  /// 封面图 ID（音源原始图片 ID）
  final String? picId;

  /// 歌词 ID（音源原始歌词 ID）
  final String? lyricId;

  /// 封面 URL（解析结果）
  final String? coverUrl;

  /// LRC 歌词全文（播放后回填）
  final String? lyrics;

  /// 更新时间
  final DateTime updatedAt;
  const LocalSongMetaData(
      {required this.songId,
      required this.source,
      required this.name,
      required this.artist,
      required this.album,
      this.picId,
      this.lyricId,
      this.coverUrl,
      this.lyrics,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['song_id'] = Variable<String>(songId);
    map['source'] = Variable<String>(source);
    map['name'] = Variable<String>(name);
    map['artist'] = Variable<String>(artist);
    map['album'] = Variable<String>(album);
    if (!nullToAbsent || picId != null) {
      map['pic_id'] = Variable<String>(picId);
    }
    if (!nullToAbsent || lyricId != null) {
      map['lyric_id'] = Variable<String>(lyricId);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || lyrics != null) {
      map['lyrics'] = Variable<String>(lyrics);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalSongMetaCompanion toCompanion(bool nullToAbsent) {
    return LocalSongMetaCompanion(
      songId: Value(songId),
      source: Value(source),
      name: Value(name),
      artist: Value(artist),
      album: Value(album),
      picId:
          picId == null && nullToAbsent ? const Value.absent() : Value(picId),
      lyricId: lyricId == null && nullToAbsent
          ? const Value.absent()
          : Value(lyricId),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      lyrics:
          lyrics == null && nullToAbsent ? const Value.absent() : Value(lyrics),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalSongMetaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSongMetaData(
      songId: serializer.fromJson<String>(json['songId']),
      source: serializer.fromJson<String>(json['source']),
      name: serializer.fromJson<String>(json['name']),
      artist: serializer.fromJson<String>(json['artist']),
      album: serializer.fromJson<String>(json['album']),
      picId: serializer.fromJson<String?>(json['picId']),
      lyricId: serializer.fromJson<String?>(json['lyricId']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      lyrics: serializer.fromJson<String?>(json['lyrics']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'songId': serializer.toJson<String>(songId),
      'source': serializer.toJson<String>(source),
      'name': serializer.toJson<String>(name),
      'artist': serializer.toJson<String>(artist),
      'album': serializer.toJson<String>(album),
      'picId': serializer.toJson<String?>(picId),
      'lyricId': serializer.toJson<String?>(lyricId),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'lyrics': serializer.toJson<String?>(lyrics),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalSongMetaData copyWith(
          {String? songId,
          String? source,
          String? name,
          String? artist,
          String? album,
          Value<String?> picId = const Value.absent(),
          Value<String?> lyricId = const Value.absent(),
          Value<String?> coverUrl = const Value.absent(),
          Value<String?> lyrics = const Value.absent(),
          DateTime? updatedAt}) =>
      LocalSongMetaData(
        songId: songId ?? this.songId,
        source: source ?? this.source,
        name: name ?? this.name,
        artist: artist ?? this.artist,
        album: album ?? this.album,
        picId: picId.present ? picId.value : this.picId,
        lyricId: lyricId.present ? lyricId.value : this.lyricId,
        coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
        lyrics: lyrics.present ? lyrics.value : this.lyrics,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalSongMetaData copyWithCompanion(LocalSongMetaCompanion data) {
    return LocalSongMetaData(
      songId: data.songId.present ? data.songId.value : this.songId,
      source: data.source.present ? data.source.value : this.source,
      name: data.name.present ? data.name.value : this.name,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      picId: data.picId.present ? data.picId.value : this.picId,
      lyricId: data.lyricId.present ? data.lyricId.value : this.lyricId,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      lyrics: data.lyrics.present ? data.lyrics.value : this.lyrics,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSongMetaData(')
          ..write('songId: $songId, ')
          ..write('source: $source, ')
          ..write('name: $name, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('picId: $picId, ')
          ..write('lyricId: $lyricId, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('lyrics: $lyrics, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(songId, source, name, artist, album, picId,
      lyricId, coverUrl, lyrics, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSongMetaData &&
          other.songId == this.songId &&
          other.source == this.source &&
          other.name == this.name &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.picId == this.picId &&
          other.lyricId == this.lyricId &&
          other.coverUrl == this.coverUrl &&
          other.lyrics == this.lyrics &&
          other.updatedAt == this.updatedAt);
}

class LocalSongMetaCompanion extends UpdateCompanion<LocalSongMetaData> {
  final Value<String> songId;
  final Value<String> source;
  final Value<String> name;
  final Value<String> artist;
  final Value<String> album;
  final Value<String?> picId;
  final Value<String?> lyricId;
  final Value<String?> coverUrl;
  final Value<String?> lyrics;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalSongMetaCompanion({
    this.songId = const Value.absent(),
    this.source = const Value.absent(),
    this.name = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.picId = const Value.absent(),
    this.lyricId = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.lyrics = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSongMetaCompanion.insert({
    required String songId,
    required String source,
    this.name = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.picId = const Value.absent(),
    this.lyricId = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.lyrics = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : songId = Value(songId),
        source = Value(source);
  static Insertable<LocalSongMetaData> custom({
    Expression<String>? songId,
    Expression<String>? source,
    Expression<String>? name,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<String>? picId,
    Expression<String>? lyricId,
    Expression<String>? coverUrl,
    Expression<String>? lyrics,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (songId != null) 'song_id': songId,
      if (source != null) 'source': source,
      if (name != null) 'name': name,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (picId != null) 'pic_id': picId,
      if (lyricId != null) 'lyric_id': lyricId,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (lyrics != null) 'lyrics': lyrics,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSongMetaCompanion copyWith(
      {Value<String>? songId,
      Value<String>? source,
      Value<String>? name,
      Value<String>? artist,
      Value<String>? album,
      Value<String?>? picId,
      Value<String?>? lyricId,
      Value<String?>? coverUrl,
      Value<String?>? lyrics,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalSongMetaCompanion(
      songId: songId ?? this.songId,
      source: source ?? this.source,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      picId: picId ?? this.picId,
      lyricId: lyricId ?? this.lyricId,
      coverUrl: coverUrl ?? this.coverUrl,
      lyrics: lyrics ?? this.lyrics,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (picId.present) {
      map['pic_id'] = Variable<String>(picId.value);
    }
    if (lyricId.present) {
      map['lyric_id'] = Variable<String>(lyricId.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (lyrics.present) {
      map['lyrics'] = Variable<String>(lyrics.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSongMetaCompanion(')
          ..write('songId: $songId, ')
          ..write('source: $source, ')
          ..write('name: $name, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('picId: $picId, ')
          ..write('lyricId: $lyricId, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('lyrics: $lyrics, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPlaylistFollowsTable extends LocalPlaylistFollows
    with TableInfo<$LocalPlaylistFollowsTable, LocalPlaylistFollow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlaylistFollowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta =
      const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
      'playlist_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _coverPicIdMeta =
      const VerificationMeta('coverPicId');
  @override
  late final GeneratedColumn<String> coverPicId = GeneratedColumn<String>(
      'cover_pic_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverSourceMeta =
      const VerificationMeta('coverSource');
  @override
  late final GeneratedColumn<String> coverSource = GeneratedColumn<String>(
      'cover_source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ownerNicknameMeta =
      const VerificationMeta('ownerNickname');
  @override
  late final GeneratedColumn<String> ownerNickname = GeneratedColumn<String>(
      'owner_nickname', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _ownerAvatarUrlMeta =
      const VerificationMeta('ownerAvatarUrl');
  @override
  late final GeneratedColumn<String> ownerAvatarUrl = GeneratedColumn<String>(
      'owner_avatar_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _songCountMeta =
      const VerificationMeta('songCount');
  @override
  late final GeneratedColumn<int> songCount = GeneratedColumn<int>(
      'song_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncedEverMeta =
      const VerificationMeta('syncedEver');
  @override
  late final GeneratedColumn<bool> syncedEver = GeneratedColumn<bool>(
      'synced_ever', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced_ever" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        playlistId,
        name,
        description,
        coverUrl,
        coverPicId,
        coverSource,
        ownerNickname,
        ownerAvatarUrl,
        songCount,
        deleted,
        isSynced,
        syncedEver,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_playlist_follows';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalPlaylistFollow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
          _playlistIdMeta,
          playlistId.isAcceptableOrUnknown(
              data['playlist_id']!, _playlistIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('cover_pic_id')) {
      context.handle(
          _coverPicIdMeta,
          coverPicId.isAcceptableOrUnknown(
              data['cover_pic_id']!, _coverPicIdMeta));
    }
    if (data.containsKey('cover_source')) {
      context.handle(
          _coverSourceMeta,
          coverSource.isAcceptableOrUnknown(
              data['cover_source']!, _coverSourceMeta));
    }
    if (data.containsKey('owner_nickname')) {
      context.handle(
          _ownerNicknameMeta,
          ownerNickname.isAcceptableOrUnknown(
              data['owner_nickname']!, _ownerNicknameMeta));
    }
    if (data.containsKey('owner_avatar_url')) {
      context.handle(
          _ownerAvatarUrlMeta,
          ownerAvatarUrl.isAcceptableOrUnknown(
              data['owner_avatar_url']!, _ownerAvatarUrlMeta));
    }
    if (data.containsKey('song_count')) {
      context.handle(_songCountMeta,
          songCount.isAcceptableOrUnknown(data['song_count']!, _songCountMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('synced_ever')) {
      context.handle(
          _syncedEverMeta,
          syncedEver.isAcceptableOrUnknown(
              data['synced_ever']!, _syncedEverMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId};
  @override
  LocalPlaylistFollow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlaylistFollow(
      playlistId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}playlist_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url'])!,
      coverPicId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_pic_id']),
      coverSource: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_source']),
      ownerNickname: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_nickname'])!,
      ownerAvatarUrl: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}owner_avatar_url'])!,
      songCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}song_count'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      syncedEver: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced_ever'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LocalPlaylistFollowsTable createAlias(String alias) {
    return $LocalPlaylistFollowsTable(attachedDatabase, alias);
  }
}

class LocalPlaylistFollow extends DataClass
    implements Insertable<LocalPlaylistFollow> {
  /// 服务端歌单 ID（唯一，收藏的源歌单）
  final int playlistId;

  /// 歌单名称
  final String name;

  /// 歌单描述
  final String description;

  /// 封面 URL
  final String coverUrl;

  /// 封面来源歌曲 pic_id（为空时按 coverUrl 或占位图；非空则客户端实时解析封面）
  final String? coverPicId;

  /// 封面来源歌曲音源标识
  final String? coverSource;

  /// 创建者昵称（同步拉取后补全）
  final String ownerNickname;

  /// 创建者头像 URL（同步拉取后补全）
  final String ownerAvatarUrl;

  /// 歌曲数（收藏时快照，同步拉取后刷新）
  final int songCount;

  /// soft delete 标记（取消收藏=1 待同步删除）
  final bool deleted;

  /// 是否已同步到服务端（0=待同步）
  final bool isSynced;

  /// 是否曾成功同步过（用于取消收藏的删除同步判定）
  final bool syncedEver;

  /// 收藏时间
  final DateTime createdAt;
  const LocalPlaylistFollow(
      {required this.playlistId,
      required this.name,
      required this.description,
      required this.coverUrl,
      this.coverPicId,
      this.coverSource,
      required this.ownerNickname,
      required this.ownerAvatarUrl,
      required this.songCount,
      required this.deleted,
      required this.isSynced,
      required this.syncedEver,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<int>(playlistId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['cover_url'] = Variable<String>(coverUrl);
    if (!nullToAbsent || coverPicId != null) {
      map['cover_pic_id'] = Variable<String>(coverPicId);
    }
    if (!nullToAbsent || coverSource != null) {
      map['cover_source'] = Variable<String>(coverSource);
    }
    map['owner_nickname'] = Variable<String>(ownerNickname);
    map['owner_avatar_url'] = Variable<String>(ownerAvatarUrl);
    map['song_count'] = Variable<int>(songCount);
    map['deleted'] = Variable<bool>(deleted);
    map['is_synced'] = Variable<bool>(isSynced);
    map['synced_ever'] = Variable<bool>(syncedEver);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalPlaylistFollowsCompanion toCompanion(bool nullToAbsent) {
    return LocalPlaylistFollowsCompanion(
      playlistId: Value(playlistId),
      name: Value(name),
      description: Value(description),
      coverUrl: Value(coverUrl),
      coverPicId: coverPicId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPicId),
      coverSource: coverSource == null && nullToAbsent
          ? const Value.absent()
          : Value(coverSource),
      ownerNickname: Value(ownerNickname),
      ownerAvatarUrl: Value(ownerAvatarUrl),
      songCount: Value(songCount),
      deleted: Value(deleted),
      isSynced: Value(isSynced),
      syncedEver: Value(syncedEver),
      createdAt: Value(createdAt),
    );
  }

  factory LocalPlaylistFollow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlaylistFollow(
      playlistId: serializer.fromJson<int>(json['playlistId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      coverUrl: serializer.fromJson<String>(json['coverUrl']),
      coverPicId: serializer.fromJson<String?>(json['coverPicId']),
      coverSource: serializer.fromJson<String?>(json['coverSource']),
      ownerNickname: serializer.fromJson<String>(json['ownerNickname']),
      ownerAvatarUrl: serializer.fromJson<String>(json['ownerAvatarUrl']),
      songCount: serializer.fromJson<int>(json['songCount']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncedEver: serializer.fromJson<bool>(json['syncedEver']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<int>(playlistId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'coverUrl': serializer.toJson<String>(coverUrl),
      'coverPicId': serializer.toJson<String?>(coverPicId),
      'coverSource': serializer.toJson<String?>(coverSource),
      'ownerNickname': serializer.toJson<String>(ownerNickname),
      'ownerAvatarUrl': serializer.toJson<String>(ownerAvatarUrl),
      'songCount': serializer.toJson<int>(songCount),
      'deleted': serializer.toJson<bool>(deleted),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncedEver': serializer.toJson<bool>(syncedEver),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalPlaylistFollow copyWith(
          {int? playlistId,
          String? name,
          String? description,
          String? coverUrl,
          Value<String?> coverPicId = const Value.absent(),
          Value<String?> coverSource = const Value.absent(),
          String? ownerNickname,
          String? ownerAvatarUrl,
          int? songCount,
          bool? deleted,
          bool? isSynced,
          bool? syncedEver,
          DateTime? createdAt}) =>
      LocalPlaylistFollow(
        playlistId: playlistId ?? this.playlistId,
        name: name ?? this.name,
        description: description ?? this.description,
        coverUrl: coverUrl ?? this.coverUrl,
        coverPicId: coverPicId.present ? coverPicId.value : this.coverPicId,
        coverSource: coverSource.present ? coverSource.value : this.coverSource,
        ownerNickname: ownerNickname ?? this.ownerNickname,
        ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
        songCount: songCount ?? this.songCount,
        deleted: deleted ?? this.deleted,
        isSynced: isSynced ?? this.isSynced,
        syncedEver: syncedEver ?? this.syncedEver,
        createdAt: createdAt ?? this.createdAt,
      );
  LocalPlaylistFollow copyWithCompanion(LocalPlaylistFollowsCompanion data) {
    return LocalPlaylistFollow(
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      coverPicId:
          data.coverPicId.present ? data.coverPicId.value : this.coverPicId,
      coverSource:
          data.coverSource.present ? data.coverSource.value : this.coverSource,
      ownerNickname: data.ownerNickname.present
          ? data.ownerNickname.value
          : this.ownerNickname,
      ownerAvatarUrl: data.ownerAvatarUrl.present
          ? data.ownerAvatarUrl.value
          : this.ownerAvatarUrl,
      songCount: data.songCount.present ? data.songCount.value : this.songCount,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      syncedEver:
          data.syncedEver.present ? data.syncedEver.value : this.syncedEver,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylistFollow(')
          ..write('playlistId: $playlistId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverPicId: $coverPicId, ')
          ..write('coverSource: $coverSource, ')
          ..write('ownerNickname: $ownerNickname, ')
          ..write('ownerAvatarUrl: $ownerAvatarUrl, ')
          ..write('songCount: $songCount, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncedEver: $syncedEver, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      playlistId,
      name,
      description,
      coverUrl,
      coverPicId,
      coverSource,
      ownerNickname,
      ownerAvatarUrl,
      songCount,
      deleted,
      isSynced,
      syncedEver,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlaylistFollow &&
          other.playlistId == this.playlistId &&
          other.name == this.name &&
          other.description == this.description &&
          other.coverUrl == this.coverUrl &&
          other.coverPicId == this.coverPicId &&
          other.coverSource == this.coverSource &&
          other.ownerNickname == this.ownerNickname &&
          other.ownerAvatarUrl == this.ownerAvatarUrl &&
          other.songCount == this.songCount &&
          other.deleted == this.deleted &&
          other.isSynced == this.isSynced &&
          other.syncedEver == this.syncedEver &&
          other.createdAt == this.createdAt);
}

class LocalPlaylistFollowsCompanion
    extends UpdateCompanion<LocalPlaylistFollow> {
  final Value<int> playlistId;
  final Value<String> name;
  final Value<String> description;
  final Value<String> coverUrl;
  final Value<String?> coverPicId;
  final Value<String?> coverSource;
  final Value<String> ownerNickname;
  final Value<String> ownerAvatarUrl;
  final Value<int> songCount;
  final Value<bool> deleted;
  final Value<bool> isSynced;
  final Value<bool> syncedEver;
  final Value<DateTime> createdAt;
  const LocalPlaylistFollowsCompanion({
    this.playlistId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.coverPicId = const Value.absent(),
    this.coverSource = const Value.absent(),
    this.ownerNickname = const Value.absent(),
    this.ownerAvatarUrl = const Value.absent(),
    this.songCount = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncedEver = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalPlaylistFollowsCompanion.insert({
    this.playlistId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.coverPicId = const Value.absent(),
    this.coverSource = const Value.absent(),
    this.ownerNickname = const Value.absent(),
    this.ownerAvatarUrl = const Value.absent(),
    this.songCount = const Value.absent(),
    this.deleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncedEver = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  static Insertable<LocalPlaylistFollow> custom({
    Expression<int>? playlistId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? coverUrl,
    Expression<String>? coverPicId,
    Expression<String>? coverSource,
    Expression<String>? ownerNickname,
    Expression<String>? ownerAvatarUrl,
    Expression<int>? songCount,
    Expression<bool>? deleted,
    Expression<bool>? isSynced,
    Expression<bool>? syncedEver,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (coverPicId != null) 'cover_pic_id': coverPicId,
      if (coverSource != null) 'cover_source': coverSource,
      if (ownerNickname != null) 'owner_nickname': ownerNickname,
      if (ownerAvatarUrl != null) 'owner_avatar_url': ownerAvatarUrl,
      if (songCount != null) 'song_count': songCount,
      if (deleted != null) 'deleted': deleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncedEver != null) 'synced_ever': syncedEver,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalPlaylistFollowsCompanion copyWith(
      {Value<int>? playlistId,
      Value<String>? name,
      Value<String>? description,
      Value<String>? coverUrl,
      Value<String?>? coverPicId,
      Value<String?>? coverSource,
      Value<String>? ownerNickname,
      Value<String>? ownerAvatarUrl,
      Value<int>? songCount,
      Value<bool>? deleted,
      Value<bool>? isSynced,
      Value<bool>? syncedEver,
      Value<DateTime>? createdAt}) {
    return LocalPlaylistFollowsCompanion(
      playlistId: playlistId ?? this.playlistId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      coverPicId: coverPicId ?? this.coverPicId,
      coverSource: coverSource ?? this.coverSource,
      ownerNickname: ownerNickname ?? this.ownerNickname,
      ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
      songCount: songCount ?? this.songCount,
      deleted: deleted ?? this.deleted,
      isSynced: isSynced ?? this.isSynced,
      syncedEver: syncedEver ?? this.syncedEver,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (coverPicId.present) {
      map['cover_pic_id'] = Variable<String>(coverPicId.value);
    }
    if (coverSource.present) {
      map['cover_source'] = Variable<String>(coverSource.value);
    }
    if (ownerNickname.present) {
      map['owner_nickname'] = Variable<String>(ownerNickname.value);
    }
    if (ownerAvatarUrl.present) {
      map['owner_avatar_url'] = Variable<String>(ownerAvatarUrl.value);
    }
    if (songCount.present) {
      map['song_count'] = Variable<int>(songCount.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncedEver.present) {
      map['synced_ever'] = Variable<bool>(syncedEver.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylistFollowsCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverPicId: $coverPicId, ')
          ..write('coverSource: $coverSource, ')
          ..write('ownerNickname: $ownerNickname, ')
          ..write('ownerAvatarUrl: $ownerAvatarUrl, ')
          ..write('songCount: $songCount, ')
          ..write('deleted: $deleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncedEver: $syncedEver, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LocalRecommendPlaylistsTable extends LocalRecommendPlaylists
    with TableInfo<$LocalRecommendPlaylistsTable, LocalRecommendPlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalRecommendPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
      'remote_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _coverPicIdMeta =
      const VerificationMeta('coverPicId');
  @override
  late final GeneratedColumn<String> coverPicId = GeneratedColumn<String>(
      'cover_pic_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverSourceMeta =
      const VerificationMeta('coverSource');
  @override
  late final GeneratedColumn<String> coverSource = GeneratedColumn<String>(
      'cover_source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('system'));
  static const VerificationMeta _songCountMeta =
      const VerificationMeta('songCount');
  @override
  late final GeneratedColumn<int> songCount = GeneratedColumn<int>(
      'song_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _playCountMeta =
      const VerificationMeta('playCount');
  @override
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
      'play_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _ownerNicknameMeta =
      const VerificationMeta('ownerNickname');
  @override
  late final GeneratedColumn<String> ownerNickname = GeneratedColumn<String>(
      'owner_nickname', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _ownerAvatarUrlMeta =
      const VerificationMeta('ownerAvatarUrl');
  @override
  late final GeneratedColumn<String> ownerAvatarUrl = GeneratedColumn<String>(
      'owner_avatar_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        remoteId,
        name,
        description,
        coverUrl,
        coverPicId,
        coverSource,
        type,
        songCount,
        playCount,
        ownerNickname,
        ownerAvatarUrl,
        orderIndex
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_recommend_playlists';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalRecommendPlaylist> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('cover_pic_id')) {
      context.handle(
          _coverPicIdMeta,
          coverPicId.isAcceptableOrUnknown(
              data['cover_pic_id']!, _coverPicIdMeta));
    }
    if (data.containsKey('cover_source')) {
      context.handle(
          _coverSourceMeta,
          coverSource.isAcceptableOrUnknown(
              data['cover_source']!, _coverSourceMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('song_count')) {
      context.handle(_songCountMeta,
          songCount.isAcceptableOrUnknown(data['song_count']!, _songCountMeta));
    }
    if (data.containsKey('play_count')) {
      context.handle(_playCountMeta,
          playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta));
    }
    if (data.containsKey('owner_nickname')) {
      context.handle(
          _ownerNicknameMeta,
          ownerNickname.isAcceptableOrUnknown(
              data['owner_nickname']!, _ownerNicknameMeta));
    }
    if (data.containsKey('owner_avatar_url')) {
      context.handle(
          _ownerAvatarUrlMeta,
          ownerAvatarUrl.isAcceptableOrUnknown(
              data['owner_avatar_url']!, _ownerAvatarUrlMeta));
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {remoteId};
  @override
  LocalRecommendPlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalRecommendPlaylist(
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remote_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url'])!,
      coverPicId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_pic_id']),
      coverSource: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_source']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      songCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}song_count'])!,
      playCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}play_count'])!,
      ownerNickname: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_nickname'])!,
      ownerAvatarUrl: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}owner_avatar_url'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
    );
  }

  @override
  $LocalRecommendPlaylistsTable createAlias(String alias) {
    return $LocalRecommendPlaylistsTable(attachedDatabase, alias);
  }
}

class LocalRecommendPlaylist extends DataClass
    implements Insertable<LocalRecommendPlaylist> {
  /// 服务端歌单 ID（唯一）
  final int remoteId;

  /// 歌单名称
  final String name;

  /// 歌单描述
  final String description;

  /// 封面 URL
  final String coverUrl;

  /// 封面来源歌曲 pic_id（为空时按 coverUrl 或占位图；非空则客户端实时解析封面）
  final String? coverPicId;

  /// 封面来源歌曲音源标识
  final String? coverSource;

  /// 歌单类型：system / user（首页分区用）
  final String type;

  /// 歌曲数（服务端快照，拉取时刷新）
  final int songCount;

  /// 播放量
  final int playCount;

  /// 创建者昵称（用户公开歌单显示）
  final String ownerNickname;

  /// 创建者头像 URL
  final String ownerAvatarUrl;

  /// 服务端返回顺序（系统在前、公开在后，原样保留展示顺序）
  final int orderIndex;
  const LocalRecommendPlaylist(
      {required this.remoteId,
      required this.name,
      required this.description,
      required this.coverUrl,
      this.coverPicId,
      this.coverSource,
      required this.type,
      required this.songCount,
      required this.playCount,
      required this.ownerNickname,
      required this.ownerAvatarUrl,
      required this.orderIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['remote_id'] = Variable<int>(remoteId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['cover_url'] = Variable<String>(coverUrl);
    if (!nullToAbsent || coverPicId != null) {
      map['cover_pic_id'] = Variable<String>(coverPicId);
    }
    if (!nullToAbsent || coverSource != null) {
      map['cover_source'] = Variable<String>(coverSource);
    }
    map['type'] = Variable<String>(type);
    map['song_count'] = Variable<int>(songCount);
    map['play_count'] = Variable<int>(playCount);
    map['owner_nickname'] = Variable<String>(ownerNickname);
    map['owner_avatar_url'] = Variable<String>(ownerAvatarUrl);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  LocalRecommendPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return LocalRecommendPlaylistsCompanion(
      remoteId: Value(remoteId),
      name: Value(name),
      description: Value(description),
      coverUrl: Value(coverUrl),
      coverPicId: coverPicId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPicId),
      coverSource: coverSource == null && nullToAbsent
          ? const Value.absent()
          : Value(coverSource),
      type: Value(type),
      songCount: Value(songCount),
      playCount: Value(playCount),
      ownerNickname: Value(ownerNickname),
      ownerAvatarUrl: Value(ownerAvatarUrl),
      orderIndex: Value(orderIndex),
    );
  }

  factory LocalRecommendPlaylist.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalRecommendPlaylist(
      remoteId: serializer.fromJson<int>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      coverUrl: serializer.fromJson<String>(json['coverUrl']),
      coverPicId: serializer.fromJson<String?>(json['coverPicId']),
      coverSource: serializer.fromJson<String?>(json['coverSource']),
      type: serializer.fromJson<String>(json['type']),
      songCount: serializer.fromJson<int>(json['songCount']),
      playCount: serializer.fromJson<int>(json['playCount']),
      ownerNickname: serializer.fromJson<String>(json['ownerNickname']),
      ownerAvatarUrl: serializer.fromJson<String>(json['ownerAvatarUrl']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'remoteId': serializer.toJson<int>(remoteId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'coverUrl': serializer.toJson<String>(coverUrl),
      'coverPicId': serializer.toJson<String?>(coverPicId),
      'coverSource': serializer.toJson<String?>(coverSource),
      'type': serializer.toJson<String>(type),
      'songCount': serializer.toJson<int>(songCount),
      'playCount': serializer.toJson<int>(playCount),
      'ownerNickname': serializer.toJson<String>(ownerNickname),
      'ownerAvatarUrl': serializer.toJson<String>(ownerAvatarUrl),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  LocalRecommendPlaylist copyWith(
          {int? remoteId,
          String? name,
          String? description,
          String? coverUrl,
          Value<String?> coverPicId = const Value.absent(),
          Value<String?> coverSource = const Value.absent(),
          String? type,
          int? songCount,
          int? playCount,
          String? ownerNickname,
          String? ownerAvatarUrl,
          int? orderIndex}) =>
      LocalRecommendPlaylist(
        remoteId: remoteId ?? this.remoteId,
        name: name ?? this.name,
        description: description ?? this.description,
        coverUrl: coverUrl ?? this.coverUrl,
        coverPicId: coverPicId.present ? coverPicId.value : this.coverPicId,
        coverSource: coverSource.present ? coverSource.value : this.coverSource,
        type: type ?? this.type,
        songCount: songCount ?? this.songCount,
        playCount: playCount ?? this.playCount,
        ownerNickname: ownerNickname ?? this.ownerNickname,
        ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
        orderIndex: orderIndex ?? this.orderIndex,
      );
  LocalRecommendPlaylist copyWithCompanion(
      LocalRecommendPlaylistsCompanion data) {
    return LocalRecommendPlaylist(
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      coverPicId:
          data.coverPicId.present ? data.coverPicId.value : this.coverPicId,
      coverSource:
          data.coverSource.present ? data.coverSource.value : this.coverSource,
      type: data.type.present ? data.type.value : this.type,
      songCount: data.songCount.present ? data.songCount.value : this.songCount,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      ownerNickname: data.ownerNickname.present
          ? data.ownerNickname.value
          : this.ownerNickname,
      ownerAvatarUrl: data.ownerAvatarUrl.present
          ? data.ownerAvatarUrl.value
          : this.ownerAvatarUrl,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecommendPlaylist(')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverPicId: $coverPicId, ')
          ..write('coverSource: $coverSource, ')
          ..write('type: $type, ')
          ..write('songCount: $songCount, ')
          ..write('playCount: $playCount, ')
          ..write('ownerNickname: $ownerNickname, ')
          ..write('ownerAvatarUrl: $ownerAvatarUrl, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      remoteId,
      name,
      description,
      coverUrl,
      coverPicId,
      coverSource,
      type,
      songCount,
      playCount,
      ownerNickname,
      ownerAvatarUrl,
      orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRecommendPlaylist &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.description == this.description &&
          other.coverUrl == this.coverUrl &&
          other.coverPicId == this.coverPicId &&
          other.coverSource == this.coverSource &&
          other.type == this.type &&
          other.songCount == this.songCount &&
          other.playCount == this.playCount &&
          other.ownerNickname == this.ownerNickname &&
          other.ownerAvatarUrl == this.ownerAvatarUrl &&
          other.orderIndex == this.orderIndex);
}

class LocalRecommendPlaylistsCompanion
    extends UpdateCompanion<LocalRecommendPlaylist> {
  final Value<int> remoteId;
  final Value<String> name;
  final Value<String> description;
  final Value<String> coverUrl;
  final Value<String?> coverPicId;
  final Value<String?> coverSource;
  final Value<String> type;
  final Value<int> songCount;
  final Value<int> playCount;
  final Value<String> ownerNickname;
  final Value<String> ownerAvatarUrl;
  final Value<int> orderIndex;
  const LocalRecommendPlaylistsCompanion({
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.coverPicId = const Value.absent(),
    this.coverSource = const Value.absent(),
    this.type = const Value.absent(),
    this.songCount = const Value.absent(),
    this.playCount = const Value.absent(),
    this.ownerNickname = const Value.absent(),
    this.ownerAvatarUrl = const Value.absent(),
    this.orderIndex = const Value.absent(),
  });
  LocalRecommendPlaylistsCompanion.insert({
    this.remoteId = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.coverPicId = const Value.absent(),
    this.coverSource = const Value.absent(),
    this.type = const Value.absent(),
    this.songCount = const Value.absent(),
    this.playCount = const Value.absent(),
    this.ownerNickname = const Value.absent(),
    this.ownerAvatarUrl = const Value.absent(),
    this.orderIndex = const Value.absent(),
  }) : name = Value(name);
  static Insertable<LocalRecommendPlaylist> custom({
    Expression<int>? remoteId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? coverUrl,
    Expression<String>? coverPicId,
    Expression<String>? coverSource,
    Expression<String>? type,
    Expression<int>? songCount,
    Expression<int>? playCount,
    Expression<String>? ownerNickname,
    Expression<String>? ownerAvatarUrl,
    Expression<int>? orderIndex,
  }) {
    return RawValuesInsertable({
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (coverPicId != null) 'cover_pic_id': coverPicId,
      if (coverSource != null) 'cover_source': coverSource,
      if (type != null) 'type': type,
      if (songCount != null) 'song_count': songCount,
      if (playCount != null) 'play_count': playCount,
      if (ownerNickname != null) 'owner_nickname': ownerNickname,
      if (ownerAvatarUrl != null) 'owner_avatar_url': ownerAvatarUrl,
      if (orderIndex != null) 'order_index': orderIndex,
    });
  }

  LocalRecommendPlaylistsCompanion copyWith(
      {Value<int>? remoteId,
      Value<String>? name,
      Value<String>? description,
      Value<String>? coverUrl,
      Value<String?>? coverPicId,
      Value<String?>? coverSource,
      Value<String>? type,
      Value<int>? songCount,
      Value<int>? playCount,
      Value<String>? ownerNickname,
      Value<String>? ownerAvatarUrl,
      Value<int>? orderIndex}) {
    return LocalRecommendPlaylistsCompanion(
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      coverPicId: coverPicId ?? this.coverPicId,
      coverSource: coverSource ?? this.coverSource,
      type: type ?? this.type,
      songCount: songCount ?? this.songCount,
      playCount: playCount ?? this.playCount,
      ownerNickname: ownerNickname ?? this.ownerNickname,
      ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (coverPicId.present) {
      map['cover_pic_id'] = Variable<String>(coverPicId.value);
    }
    if (coverSource.present) {
      map['cover_source'] = Variable<String>(coverSource.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (songCount.present) {
      map['song_count'] = Variable<int>(songCount.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (ownerNickname.present) {
      map['owner_nickname'] = Variable<String>(ownerNickname.value);
    }
    if (ownerAvatarUrl.present) {
      map['owner_avatar_url'] = Variable<String>(ownerAvatarUrl.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecommendPlaylistsCompanion(')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverPicId: $coverPicId, ')
          ..write('coverSource: $coverSource, ')
          ..write('type: $type, ')
          ..write('songCount: $songCount, ')
          ..write('playCount: $playCount, ')
          ..write('ownerNickname: $ownerNickname, ')
          ..write('ownerAvatarUrl: $ownerAvatarUrl, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }
}

class $LocalRecommendPlaylistSongsTable extends LocalRecommendPlaylistSongs
    with
        TableInfo<$LocalRecommendPlaylistSongsTable,
            LocalRecommendPlaylistSong> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalRecommendPlaylistSongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistRemoteIdMeta =
      const VerificationMeta('playlistRemoteId');
  @override
  late final GeneratedColumn<int> playlistRemoteId = GeneratedColumn<int>(
      'playlist_remote_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
      'song_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _songNameMeta =
      const VerificationMeta('songName');
  @override
  late final GeneratedColumn<String> songName = GeneratedColumn<String>(
      'song_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
      'artist', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
      'album', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _picIdMeta = const VerificationMeta('picId');
  @override
  late final GeneratedColumn<String> picId = GeneratedColumn<String>(
      'pic_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lyricIdMeta =
      const VerificationMeta('lyricId');
  @override
  late final GeneratedColumn<String> lyricId = GeneratedColumn<String>(
      'lyric_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        playlistRemoteId,
        songId,
        source,
        songName,
        artist,
        album,
        coverUrl,
        picId,
        lyricId,
        sortOrder
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_recommend_playlist_songs';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalRecommendPlaylistSong> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_remote_id')) {
      context.handle(
          _playlistRemoteIdMeta,
          playlistRemoteId.isAcceptableOrUnknown(
              data['playlist_remote_id']!, _playlistRemoteIdMeta));
    } else if (isInserting) {
      context.missing(_playlistRemoteIdMeta);
    }
    if (data.containsKey('song_id')) {
      context.handle(_songIdMeta,
          songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta));
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('song_name')) {
      context.handle(_songNameMeta,
          songName.isAcceptableOrUnknown(data['song_name']!, _songNameMeta));
    } else if (isInserting) {
      context.missing(_songNameMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(_artistMeta,
          artist.isAcceptableOrUnknown(data['artist']!, _artistMeta));
    }
    if (data.containsKey('album')) {
      context.handle(
          _albumMeta, album.isAcceptableOrUnknown(data['album']!, _albumMeta));
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('pic_id')) {
      context.handle(
          _picIdMeta, picId.isAcceptableOrUnknown(data['pic_id']!, _picIdMeta));
    }
    if (data.containsKey('lyric_id')) {
      context.handle(_lyricIdMeta,
          lyricId.isAcceptableOrUnknown(data['lyric_id']!, _lyricIdMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistRemoteId, songId, source};
  @override
  LocalRecommendPlaylistSong map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalRecommendPlaylistSong(
      playlistRemoteId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}playlist_remote_id'])!,
      songId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      songName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song_name'])!,
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist'])!,
      album: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album'])!,
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url']),
      picId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pic_id']),
      lyricId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lyric_id']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $LocalRecommendPlaylistSongsTable createAlias(String alias) {
    return $LocalRecommendPlaylistSongsTable(attachedDatabase, alias);
  }
}

class LocalRecommendPlaylistSong extends DataClass
    implements Insertable<LocalRecommendPlaylistSong> {
  /// 所属推荐歌单服务端 ID
  final int playlistRemoteId;

  /// 歌曲 ID（原始音源 ID）
  final String songId;

  /// 音源标识
  final String source;

  /// 歌曲名
  final String songName;

  /// 歌手
  final String artist;

  /// 专辑
  final String album;

  /// 封面 URL
  final String? coverUrl;

  /// 封面图 pic_id（音源原始图片 ID）
  final String? picId;

  /// 歌词 ID（音源原始歌词 ID）
  final String? lyricId;

  /// 歌单内排序序号
  final int sortOrder;
  const LocalRecommendPlaylistSong(
      {required this.playlistRemoteId,
      required this.songId,
      required this.source,
      required this.songName,
      required this.artist,
      required this.album,
      this.coverUrl,
      this.picId,
      this.lyricId,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_remote_id'] = Variable<int>(playlistRemoteId);
    map['song_id'] = Variable<String>(songId);
    map['source'] = Variable<String>(source);
    map['song_name'] = Variable<String>(songName);
    map['artist'] = Variable<String>(artist);
    map['album'] = Variable<String>(album);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || picId != null) {
      map['pic_id'] = Variable<String>(picId);
    }
    if (!nullToAbsent || lyricId != null) {
      map['lyric_id'] = Variable<String>(lyricId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  LocalRecommendPlaylistSongsCompanion toCompanion(bool nullToAbsent) {
    return LocalRecommendPlaylistSongsCompanion(
      playlistRemoteId: Value(playlistRemoteId),
      songId: Value(songId),
      source: Value(source),
      songName: Value(songName),
      artist: Value(artist),
      album: Value(album),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      picId:
          picId == null && nullToAbsent ? const Value.absent() : Value(picId),
      lyricId: lyricId == null && nullToAbsent
          ? const Value.absent()
          : Value(lyricId),
      sortOrder: Value(sortOrder),
    );
  }

  factory LocalRecommendPlaylistSong.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalRecommendPlaylistSong(
      playlistRemoteId: serializer.fromJson<int>(json['playlistRemoteId']),
      songId: serializer.fromJson<String>(json['songId']),
      source: serializer.fromJson<String>(json['source']),
      songName: serializer.fromJson<String>(json['songName']),
      artist: serializer.fromJson<String>(json['artist']),
      album: serializer.fromJson<String>(json['album']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      picId: serializer.fromJson<String?>(json['picId']),
      lyricId: serializer.fromJson<String?>(json['lyricId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistRemoteId': serializer.toJson<int>(playlistRemoteId),
      'songId': serializer.toJson<String>(songId),
      'source': serializer.toJson<String>(source),
      'songName': serializer.toJson<String>(songName),
      'artist': serializer.toJson<String>(artist),
      'album': serializer.toJson<String>(album),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'picId': serializer.toJson<String?>(picId),
      'lyricId': serializer.toJson<String?>(lyricId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  LocalRecommendPlaylistSong copyWith(
          {int? playlistRemoteId,
          String? songId,
          String? source,
          String? songName,
          String? artist,
          String? album,
          Value<String?> coverUrl = const Value.absent(),
          Value<String?> picId = const Value.absent(),
          Value<String?> lyricId = const Value.absent(),
          int? sortOrder}) =>
      LocalRecommendPlaylistSong(
        playlistRemoteId: playlistRemoteId ?? this.playlistRemoteId,
        songId: songId ?? this.songId,
        source: source ?? this.source,
        songName: songName ?? this.songName,
        artist: artist ?? this.artist,
        album: album ?? this.album,
        coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
        picId: picId.present ? picId.value : this.picId,
        lyricId: lyricId.present ? lyricId.value : this.lyricId,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  LocalRecommendPlaylistSong copyWithCompanion(
      LocalRecommendPlaylistSongsCompanion data) {
    return LocalRecommendPlaylistSong(
      playlistRemoteId: data.playlistRemoteId.present
          ? data.playlistRemoteId.value
          : this.playlistRemoteId,
      songId: data.songId.present ? data.songId.value : this.songId,
      source: data.source.present ? data.source.value : this.source,
      songName: data.songName.present ? data.songName.value : this.songName,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      picId: data.picId.present ? data.picId.value : this.picId,
      lyricId: data.lyricId.present ? data.lyricId.value : this.lyricId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecommendPlaylistSong(')
          ..write('playlistRemoteId: $playlistRemoteId, ')
          ..write('songId: $songId, ')
          ..write('source: $source, ')
          ..write('songName: $songName, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('picId: $picId, ')
          ..write('lyricId: $lyricId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistRemoteId, songId, source, songName,
      artist, album, coverUrl, picId, lyricId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRecommendPlaylistSong &&
          other.playlistRemoteId == this.playlistRemoteId &&
          other.songId == this.songId &&
          other.source == this.source &&
          other.songName == this.songName &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.coverUrl == this.coverUrl &&
          other.picId == this.picId &&
          other.lyricId == this.lyricId &&
          other.sortOrder == this.sortOrder);
}

class LocalRecommendPlaylistSongsCompanion
    extends UpdateCompanion<LocalRecommendPlaylistSong> {
  final Value<int> playlistRemoteId;
  final Value<String> songId;
  final Value<String> source;
  final Value<String> songName;
  final Value<String> artist;
  final Value<String> album;
  final Value<String?> coverUrl;
  final Value<String?> picId;
  final Value<String?> lyricId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const LocalRecommendPlaylistSongsCompanion({
    this.playlistRemoteId = const Value.absent(),
    this.songId = const Value.absent(),
    this.source = const Value.absent(),
    this.songName = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.picId = const Value.absent(),
    this.lyricId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalRecommendPlaylistSongsCompanion.insert({
    required int playlistRemoteId,
    required String songId,
    this.source = const Value.absent(),
    required String songName,
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.picId = const Value.absent(),
    this.lyricId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : playlistRemoteId = Value(playlistRemoteId),
        songId = Value(songId),
        songName = Value(songName);
  static Insertable<LocalRecommendPlaylistSong> custom({
    Expression<int>? playlistRemoteId,
    Expression<String>? songId,
    Expression<String>? source,
    Expression<String>? songName,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<String>? coverUrl,
    Expression<String>? picId,
    Expression<String>? lyricId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistRemoteId != null) 'playlist_remote_id': playlistRemoteId,
      if (songId != null) 'song_id': songId,
      if (source != null) 'source': source,
      if (songName != null) 'song_name': songName,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (picId != null) 'pic_id': picId,
      if (lyricId != null) 'lyric_id': lyricId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalRecommendPlaylistSongsCompanion copyWith(
      {Value<int>? playlistRemoteId,
      Value<String>? songId,
      Value<String>? source,
      Value<String>? songName,
      Value<String>? artist,
      Value<String>? album,
      Value<String?>? coverUrl,
      Value<String?>? picId,
      Value<String?>? lyricId,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return LocalRecommendPlaylistSongsCompanion(
      playlistRemoteId: playlistRemoteId ?? this.playlistRemoteId,
      songId: songId ?? this.songId,
      source: source ?? this.source,
      songName: songName ?? this.songName,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverUrl: coverUrl ?? this.coverUrl,
      picId: picId ?? this.picId,
      lyricId: lyricId ?? this.lyricId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistRemoteId.present) {
      map['playlist_remote_id'] = Variable<int>(playlistRemoteId.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (songName.present) {
      map['song_name'] = Variable<String>(songName.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (picId.present) {
      map['pic_id'] = Variable<String>(picId.value);
    }
    if (lyricId.present) {
      map['lyric_id'] = Variable<String>(lyricId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecommendPlaylistSongsCompanion(')
          ..write('playlistRemoteId: $playlistRemoteId, ')
          ..write('songId: $songId, ')
          ..write('source: $source, ')
          ..write('songName: $songName, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('picId: $picId, ')
          ..write('lyricId: $lyricId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPicCoversTable extends LocalPicCovers
    with TableInfo<$LocalPicCoversTable, LocalPicCover> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPicCoversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _picIdMeta = const VerificationMeta('picId');
  @override
  late final GeneratedColumn<String> picId = GeneratedColumn<String>(
      'pic_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [picId, source, coverUrl, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_pic_covers';
  @override
  VerificationContext validateIntegrity(Insertable<LocalPicCover> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pic_id')) {
      context.handle(
          _picIdMeta, picId.isAcceptableOrUnknown(data['pic_id']!, _picIdMeta));
    } else if (isInserting) {
      context.missing(_picIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    } else if (isInserting) {
      context.missing(_coverUrlMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {picId, source};
  @override
  LocalPicCover map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPicCover(
      picId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pic_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalPicCoversTable createAlias(String alias) {
    return $LocalPicCoversTable(attachedDatabase, alias);
  }
}

class LocalPicCover extends DataClass implements Insertable<LocalPicCover> {
  /// 封面图 ID（音源原始图片 ID）
  final String picId;

  /// 音源标识
  final String source;

  /// 封面 URL（解析结果）
  final String coverUrl;

  /// 更新时间
  final DateTime updatedAt;
  const LocalPicCover(
      {required this.picId,
      required this.source,
      required this.coverUrl,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pic_id'] = Variable<String>(picId);
    map['source'] = Variable<String>(source);
    map['cover_url'] = Variable<String>(coverUrl);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalPicCoversCompanion toCompanion(bool nullToAbsent) {
    return LocalPicCoversCompanion(
      picId: Value(picId),
      source: Value(source),
      coverUrl: Value(coverUrl),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalPicCover.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPicCover(
      picId: serializer.fromJson<String>(json['picId']),
      source: serializer.fromJson<String>(json['source']),
      coverUrl: serializer.fromJson<String>(json['coverUrl']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'picId': serializer.toJson<String>(picId),
      'source': serializer.toJson<String>(source),
      'coverUrl': serializer.toJson<String>(coverUrl),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalPicCover copyWith(
          {String? picId,
          String? source,
          String? coverUrl,
          DateTime? updatedAt}) =>
      LocalPicCover(
        picId: picId ?? this.picId,
        source: source ?? this.source,
        coverUrl: coverUrl ?? this.coverUrl,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalPicCover copyWithCompanion(LocalPicCoversCompanion data) {
    return LocalPicCover(
      picId: data.picId.present ? data.picId.value : this.picId,
      source: data.source.present ? data.source.value : this.source,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPicCover(')
          ..write('picId: $picId, ')
          ..write('source: $source, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(picId, source, coverUrl, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPicCover &&
          other.picId == this.picId &&
          other.source == this.source &&
          other.coverUrl == this.coverUrl &&
          other.updatedAt == this.updatedAt);
}

class LocalPicCoversCompanion extends UpdateCompanion<LocalPicCover> {
  final Value<String> picId;
  final Value<String> source;
  final Value<String> coverUrl;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalPicCoversCompanion({
    this.picId = const Value.absent(),
    this.source = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPicCoversCompanion.insert({
    required String picId,
    required String source,
    required String coverUrl,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : picId = Value(picId),
        source = Value(source),
        coverUrl = Value(coverUrl);
  static Insertable<LocalPicCover> custom({
    Expression<String>? picId,
    Expression<String>? source,
    Expression<String>? coverUrl,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (picId != null) 'pic_id': picId,
      if (source != null) 'source': source,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPicCoversCompanion copyWith(
      {Value<String>? picId,
      Value<String>? source,
      Value<String>? coverUrl,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalPicCoversCompanion(
      picId: picId ?? this.picId,
      source: source ?? this.source,
      coverUrl: coverUrl ?? this.coverUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (picId.present) {
      map['pic_id'] = Variable<String>(picId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPicCoversCompanion(')
          ..write('picId: $picId, ')
          ..write('source: $source, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDownloadsTable extends LocalDownloads
    with TableInfo<$LocalDownloadsTable, LocalDownload> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
      'song_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
      'artist', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
      'album', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _picIdMeta = const VerificationMeta('picId');
  @override
  late final GeneratedColumn<String> picId = GeneratedColumn<String>(
      'pic_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lyricIdMeta =
      const VerificationMeta('lyricId');
  @override
  late final GeneratedColumn<String> lyricId = GeneratedColumn<String>(
      'lyric_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _folderPathMeta =
      const VerificationMeta('folderPath');
  @override
  late final GeneratedColumn<String> folderPath = GeneratedColumn<String>(
      'folder_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _audioPathMeta =
      const VerificationMeta('audioPath');
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
      'audio_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _coverPathMeta =
      const VerificationMeta('coverPath');
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
      'cover_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lyricsPathMeta =
      const VerificationMeta('lyricsPath');
  @override
  late final GeneratedColumn<String> lyricsPath = GeneratedColumn<String>(
      'lyrics_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _downloadedAtMeta =
      const VerificationMeta('downloadedAt');
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
      'downloaded_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        songId,
        source,
        name,
        artist,
        album,
        picId,
        lyricId,
        coverUrl,
        folderPath,
        audioPath,
        coverPath,
        lyricsPath,
        downloadedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_downloads';
  @override
  VerificationContext validateIntegrity(Insertable<LocalDownload> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('song_id')) {
      context.handle(_songIdMeta,
          songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta));
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(_artistMeta,
          artist.isAcceptableOrUnknown(data['artist']!, _artistMeta));
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('album')) {
      context.handle(
          _albumMeta, album.isAcceptableOrUnknown(data['album']!, _albumMeta));
    }
    if (data.containsKey('pic_id')) {
      context.handle(
          _picIdMeta, picId.isAcceptableOrUnknown(data['pic_id']!, _picIdMeta));
    }
    if (data.containsKey('lyric_id')) {
      context.handle(_lyricIdMeta,
          lyricId.isAcceptableOrUnknown(data['lyric_id']!, _lyricIdMeta));
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('folder_path')) {
      context.handle(
          _folderPathMeta,
          folderPath.isAcceptableOrUnknown(
              data['folder_path']!, _folderPathMeta));
    } else if (isInserting) {
      context.missing(_folderPathMeta);
    }
    if (data.containsKey('audio_path')) {
      context.handle(_audioPathMeta,
          audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta));
    } else if (isInserting) {
      context.missing(_audioPathMeta);
    }
    if (data.containsKey('cover_path')) {
      context.handle(_coverPathMeta,
          coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta));
    }
    if (data.containsKey('lyrics_path')) {
      context.handle(
          _lyricsPathMeta,
          lyricsPath.isAcceptableOrUnknown(
              data['lyrics_path']!, _lyricsPathMeta));
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
          _downloadedAtMeta,
          downloadedAt.isAcceptableOrUnknown(
              data['downloaded_at']!, _downloadedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {songId, source};
  @override
  LocalDownload map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDownload(
      songId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist'])!,
      album: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album'])!,
      picId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pic_id']),
      lyricId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lyric_id']),
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url']),
      folderPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_path'])!,
      audioPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_path'])!,
      coverPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_path']),
      lyricsPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lyrics_path']),
      downloadedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}downloaded_at'])!,
    );
  }

  @override
  $LocalDownloadsTable createAlias(String alias) {
    return $LocalDownloadsTable(attachedDatabase, alias);
  }
}

class LocalDownload extends DataClass implements Insertable<LocalDownload> {
  /// 歌曲 ID（原始音源 ID）
  final String songId;

  /// 音源标识（netease/qqmusic/joox 等）
  final String source;

  /// 歌曲名
  final String name;

  /// 歌手
  final String artist;

  /// 专辑
  final String album;

  /// 封面图 pic_id（音源原始图片 ID，便于重取封面）
  final String? picId;

  /// 歌词 ID
  final String? lyricId;

  /// 封面 URL（解析结果）
  final String? coverUrl;

  /// 歌曲本地子文件夹绝对路径（如 /storage/emulated/0/Download/JoyTune/晴天-周杰伦）
  final String folderPath;

  /// 音频本地路径（folderPath/歌曲.mp3）
  final String audioPath;

  /// 封面本地路径（folderPath/图片.jpg，下载失败可空）
  final String? coverPath;

  /// 歌词本地路径（folderPath/歌词.lrc，下载失败可空）
  final String? lyricsPath;

  /// 下载时间
  final DateTime downloadedAt;
  const LocalDownload(
      {required this.songId,
      required this.source,
      required this.name,
      required this.artist,
      required this.album,
      this.picId,
      this.lyricId,
      this.coverUrl,
      required this.folderPath,
      required this.audioPath,
      this.coverPath,
      this.lyricsPath,
      required this.downloadedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['song_id'] = Variable<String>(songId);
    map['source'] = Variable<String>(source);
    map['name'] = Variable<String>(name);
    map['artist'] = Variable<String>(artist);
    map['album'] = Variable<String>(album);
    if (!nullToAbsent || picId != null) {
      map['pic_id'] = Variable<String>(picId);
    }
    if (!nullToAbsent || lyricId != null) {
      map['lyric_id'] = Variable<String>(lyricId);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    map['folder_path'] = Variable<String>(folderPath);
    map['audio_path'] = Variable<String>(audioPath);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    if (!nullToAbsent || lyricsPath != null) {
      map['lyrics_path'] = Variable<String>(lyricsPath);
    }
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    return map;
  }

  LocalDownloadsCompanion toCompanion(bool nullToAbsent) {
    return LocalDownloadsCompanion(
      songId: Value(songId),
      source: Value(source),
      name: Value(name),
      artist: Value(artist),
      album: Value(album),
      picId:
          picId == null && nullToAbsent ? const Value.absent() : Value(picId),
      lyricId: lyricId == null && nullToAbsent
          ? const Value.absent()
          : Value(lyricId),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      folderPath: Value(folderPath),
      audioPath: Value(audioPath),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      lyricsPath: lyricsPath == null && nullToAbsent
          ? const Value.absent()
          : Value(lyricsPath),
      downloadedAt: Value(downloadedAt),
    );
  }

  factory LocalDownload.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDownload(
      songId: serializer.fromJson<String>(json['songId']),
      source: serializer.fromJson<String>(json['source']),
      name: serializer.fromJson<String>(json['name']),
      artist: serializer.fromJson<String>(json['artist']),
      album: serializer.fromJson<String>(json['album']),
      picId: serializer.fromJson<String?>(json['picId']),
      lyricId: serializer.fromJson<String?>(json['lyricId']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      folderPath: serializer.fromJson<String>(json['folderPath']),
      audioPath: serializer.fromJson<String>(json['audioPath']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      lyricsPath: serializer.fromJson<String?>(json['lyricsPath']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'songId': serializer.toJson<String>(songId),
      'source': serializer.toJson<String>(source),
      'name': serializer.toJson<String>(name),
      'artist': serializer.toJson<String>(artist),
      'album': serializer.toJson<String>(album),
      'picId': serializer.toJson<String?>(picId),
      'lyricId': serializer.toJson<String?>(lyricId),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'folderPath': serializer.toJson<String>(folderPath),
      'audioPath': serializer.toJson<String>(audioPath),
      'coverPath': serializer.toJson<String?>(coverPath),
      'lyricsPath': serializer.toJson<String?>(lyricsPath),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
    };
  }

  LocalDownload copyWith(
          {String? songId,
          String? source,
          String? name,
          String? artist,
          String? album,
          Value<String?> picId = const Value.absent(),
          Value<String?> lyricId = const Value.absent(),
          Value<String?> coverUrl = const Value.absent(),
          String? folderPath,
          String? audioPath,
          Value<String?> coverPath = const Value.absent(),
          Value<String?> lyricsPath = const Value.absent(),
          DateTime? downloadedAt}) =>
      LocalDownload(
        songId: songId ?? this.songId,
        source: source ?? this.source,
        name: name ?? this.name,
        artist: artist ?? this.artist,
        album: album ?? this.album,
        picId: picId.present ? picId.value : this.picId,
        lyricId: lyricId.present ? lyricId.value : this.lyricId,
        coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
        folderPath: folderPath ?? this.folderPath,
        audioPath: audioPath ?? this.audioPath,
        coverPath: coverPath.present ? coverPath.value : this.coverPath,
        lyricsPath: lyricsPath.present ? lyricsPath.value : this.lyricsPath,
        downloadedAt: downloadedAt ?? this.downloadedAt,
      );
  LocalDownload copyWithCompanion(LocalDownloadsCompanion data) {
    return LocalDownload(
      songId: data.songId.present ? data.songId.value : this.songId,
      source: data.source.present ? data.source.value : this.source,
      name: data.name.present ? data.name.value : this.name,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      picId: data.picId.present ? data.picId.value : this.picId,
      lyricId: data.lyricId.present ? data.lyricId.value : this.lyricId,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      folderPath:
          data.folderPath.present ? data.folderPath.value : this.folderPath,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      lyricsPath:
          data.lyricsPath.present ? data.lyricsPath.value : this.lyricsPath,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDownload(')
          ..write('songId: $songId, ')
          ..write('source: $source, ')
          ..write('name: $name, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('picId: $picId, ')
          ..write('lyricId: $lyricId, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('folderPath: $folderPath, ')
          ..write('audioPath: $audioPath, ')
          ..write('coverPath: $coverPath, ')
          ..write('lyricsPath: $lyricsPath, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      songId,
      source,
      name,
      artist,
      album,
      picId,
      lyricId,
      coverUrl,
      folderPath,
      audioPath,
      coverPath,
      lyricsPath,
      downloadedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDownload &&
          other.songId == this.songId &&
          other.source == this.source &&
          other.name == this.name &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.picId == this.picId &&
          other.lyricId == this.lyricId &&
          other.coverUrl == this.coverUrl &&
          other.folderPath == this.folderPath &&
          other.audioPath == this.audioPath &&
          other.coverPath == this.coverPath &&
          other.lyricsPath == this.lyricsPath &&
          other.downloadedAt == this.downloadedAt);
}

class LocalDownloadsCompanion extends UpdateCompanion<LocalDownload> {
  final Value<String> songId;
  final Value<String> source;
  final Value<String> name;
  final Value<String> artist;
  final Value<String> album;
  final Value<String?> picId;
  final Value<String?> lyricId;
  final Value<String?> coverUrl;
  final Value<String> folderPath;
  final Value<String> audioPath;
  final Value<String?> coverPath;
  final Value<String?> lyricsPath;
  final Value<DateTime> downloadedAt;
  final Value<int> rowid;
  const LocalDownloadsCompanion({
    this.songId = const Value.absent(),
    this.source = const Value.absent(),
    this.name = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.picId = const Value.absent(),
    this.lyricId = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.folderPath = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.lyricsPath = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDownloadsCompanion.insert({
    required String songId,
    required String source,
    required String name,
    required String artist,
    this.album = const Value.absent(),
    this.picId = const Value.absent(),
    this.lyricId = const Value.absent(),
    this.coverUrl = const Value.absent(),
    required String folderPath,
    required String audioPath,
    this.coverPath = const Value.absent(),
    this.lyricsPath = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : songId = Value(songId),
        source = Value(source),
        name = Value(name),
        artist = Value(artist),
        folderPath = Value(folderPath),
        audioPath = Value(audioPath);
  static Insertable<LocalDownload> custom({
    Expression<String>? songId,
    Expression<String>? source,
    Expression<String>? name,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<String>? picId,
    Expression<String>? lyricId,
    Expression<String>? coverUrl,
    Expression<String>? folderPath,
    Expression<String>? audioPath,
    Expression<String>? coverPath,
    Expression<String>? lyricsPath,
    Expression<DateTime>? downloadedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (songId != null) 'song_id': songId,
      if (source != null) 'source': source,
      if (name != null) 'name': name,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (picId != null) 'pic_id': picId,
      if (lyricId != null) 'lyric_id': lyricId,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (folderPath != null) 'folder_path': folderPath,
      if (audioPath != null) 'audio_path': audioPath,
      if (coverPath != null) 'cover_path': coverPath,
      if (lyricsPath != null) 'lyrics_path': lyricsPath,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDownloadsCompanion copyWith(
      {Value<String>? songId,
      Value<String>? source,
      Value<String>? name,
      Value<String>? artist,
      Value<String>? album,
      Value<String?>? picId,
      Value<String?>? lyricId,
      Value<String?>? coverUrl,
      Value<String>? folderPath,
      Value<String>? audioPath,
      Value<String?>? coverPath,
      Value<String?>? lyricsPath,
      Value<DateTime>? downloadedAt,
      Value<int>? rowid}) {
    return LocalDownloadsCompanion(
      songId: songId ?? this.songId,
      source: source ?? this.source,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      picId: picId ?? this.picId,
      lyricId: lyricId ?? this.lyricId,
      coverUrl: coverUrl ?? this.coverUrl,
      folderPath: folderPath ?? this.folderPath,
      audioPath: audioPath ?? this.audioPath,
      coverPath: coverPath ?? this.coverPath,
      lyricsPath: lyricsPath ?? this.lyricsPath,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (picId.present) {
      map['pic_id'] = Variable<String>(picId.value);
    }
    if (lyricId.present) {
      map['lyric_id'] = Variable<String>(lyricId.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (folderPath.present) {
      map['folder_path'] = Variable<String>(folderPath.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (lyricsPath.present) {
      map['lyrics_path'] = Variable<String>(lyricsPath.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDownloadsCompanion(')
          ..write('songId: $songId, ')
          ..write('source: $source, ')
          ..write('name: $name, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('picId: $picId, ')
          ..write('lyricId: $lyricId, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('folderPath: $folderPath, ')
          ..write('audioPath: $audioPath, ')
          ..write('coverPath: $coverPath, ')
          ..write('lyricsPath: $lyricsPath, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalFavoritesTable localFavorites = $LocalFavoritesTable(this);
  late final $LocalPlaylistsTable localPlaylists = $LocalPlaylistsTable(this);
  late final $LocalPlaylistSongsTable localPlaylistSongs =
      $LocalPlaylistSongsTable(this);
  late final $LocalPlayRecordsTable localPlayRecords =
      $LocalPlayRecordsTable(this);
  late final $LocalSearchHistoryTable localSearchHistory =
      $LocalSearchHistoryTable(this);
  late final $LocalPlaySessionsTable localPlaySessions =
      $LocalPlaySessionsTable(this);
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  late final $LocalSongMetaTable localSongMeta = $LocalSongMetaTable(this);
  late final $LocalPlaylistFollowsTable localPlaylistFollows =
      $LocalPlaylistFollowsTable(this);
  late final $LocalRecommendPlaylistsTable localRecommendPlaylists =
      $LocalRecommendPlaylistsTable(this);
  late final $LocalRecommendPlaylistSongsTable localRecommendPlaylistSongs =
      $LocalRecommendPlaylistSongsTable(this);
  late final $LocalPicCoversTable localPicCovers = $LocalPicCoversTable(this);
  late final $LocalDownloadsTable localDownloads = $LocalDownloadsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        localFavorites,
        localPlaylists,
        localPlaylistSongs,
        localPlayRecords,
        localSearchHistory,
        localPlaySessions,
        localSettings,
        localSongMeta,
        localPlaylistFollows,
        localRecommendPlaylists,
        localRecommendPlaylistSongs,
        localPicCovers,
        localDownloads
      ];
}

typedef $$LocalFavoritesTableCreateCompanionBuilder = LocalFavoritesCompanion
    Function({
  required String songId,
  required String source,
  required String name,
  required String artist,
  Value<String> album,
  Value<String?> picId,
  Value<String?> lyricId,
  Value<String?> audioUrl,
  Value<String?> coverUrl,
  Value<String?> lyricsUrl,
  Value<bool> deleted,
  Value<bool> isSynced,
  Value<bool> syncedEver,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$LocalFavoritesTableUpdateCompanionBuilder = LocalFavoritesCompanion
    Function({
  Value<String> songId,
  Value<String> source,
  Value<String> name,
  Value<String> artist,
  Value<String> album,
  Value<String?> picId,
  Value<String?> lyricId,
  Value<String?> audioUrl,
  Value<String?> coverUrl,
  Value<String?> lyricsUrl,
  Value<bool> deleted,
  Value<bool> isSynced,
  Value<bool> syncedEver,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalFavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalFavoritesTable> {
  $$LocalFavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get songId => $composableBuilder(
      column: $table.songId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get picId => $composableBuilder(
      column: $table.picId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lyricId => $composableBuilder(
      column: $table.lyricId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioUrl => $composableBuilder(
      column: $table.audioUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lyricsUrl => $composableBuilder(
      column: $table.lyricsUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get syncedEver => $composableBuilder(
      column: $table.syncedEver, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalFavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalFavoritesTable> {
  $$LocalFavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get songId => $composableBuilder(
      column: $table.songId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get picId => $composableBuilder(
      column: $table.picId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lyricId => $composableBuilder(
      column: $table.lyricId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioUrl => $composableBuilder(
      column: $table.audioUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lyricsUrl => $composableBuilder(
      column: $table.lyricsUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get syncedEver => $composableBuilder(
      column: $table.syncedEver, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalFavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalFavoritesTable> {
  $$LocalFavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get picId =>
      $composableBuilder(column: $table.picId, builder: (column) => column);

  GeneratedColumn<String> get lyricId =>
      $composableBuilder(column: $table.lyricId, builder: (column) => column);

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get lyricsUrl =>
      $composableBuilder(column: $table.lyricsUrl, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get syncedEver => $composableBuilder(
      column: $table.syncedEver, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalFavoritesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalFavoritesTable,
    LocalFavorite,
    $$LocalFavoritesTableFilterComposer,
    $$LocalFavoritesTableOrderingComposer,
    $$LocalFavoritesTableAnnotationComposer,
    $$LocalFavoritesTableCreateCompanionBuilder,
    $$LocalFavoritesTableUpdateCompanionBuilder,
    (
      LocalFavorite,
      BaseReferences<_$AppDatabase, $LocalFavoritesTable, LocalFavorite>
    ),
    LocalFavorite,
    PrefetchHooks Function()> {
  $$LocalFavoritesTableTableManager(
      _$AppDatabase db, $LocalFavoritesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalFavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalFavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalFavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> songId = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> artist = const Value.absent(),
            Value<String> album = const Value.absent(),
            Value<String?> picId = const Value.absent(),
            Value<String?> lyricId = const Value.absent(),
            Value<String?> audioUrl = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> lyricsUrl = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<bool> syncedEver = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalFavoritesCompanion(
            songId: songId,
            source: source,
            name: name,
            artist: artist,
            album: album,
            picId: picId,
            lyricId: lyricId,
            audioUrl: audioUrl,
            coverUrl: coverUrl,
            lyricsUrl: lyricsUrl,
            deleted: deleted,
            isSynced: isSynced,
            syncedEver: syncedEver,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String songId,
            required String source,
            required String name,
            required String artist,
            Value<String> album = const Value.absent(),
            Value<String?> picId = const Value.absent(),
            Value<String?> lyricId = const Value.absent(),
            Value<String?> audioUrl = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> lyricsUrl = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<bool> syncedEver = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalFavoritesCompanion.insert(
            songId: songId,
            source: source,
            name: name,
            artist: artist,
            album: album,
            picId: picId,
            lyricId: lyricId,
            audioUrl: audioUrl,
            coverUrl: coverUrl,
            lyricsUrl: lyricsUrl,
            deleted: deleted,
            isSynced: isSynced,
            syncedEver: syncedEver,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalFavoritesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalFavoritesTable,
    LocalFavorite,
    $$LocalFavoritesTableFilterComposer,
    $$LocalFavoritesTableOrderingComposer,
    $$LocalFavoritesTableAnnotationComposer,
    $$LocalFavoritesTableCreateCompanionBuilder,
    $$LocalFavoritesTableUpdateCompanionBuilder,
    (
      LocalFavorite,
      BaseReferences<_$AppDatabase, $LocalFavoritesTable, LocalFavorite>
    ),
    LocalFavorite,
    PrefetchHooks Function()>;
typedef $$LocalPlaylistsTableCreateCompanionBuilder = LocalPlaylistsCompanion
    Function({
  required String id,
  Value<int?> remoteId,
  required String name,
  Value<String> description,
  Value<String> coverUrl,
  Value<String?> coverPicId,
  Value<String?> coverSource,
  Value<bool> isPublic,
  Value<bool> deleted,
  Value<bool> isSynced,
  Value<bool> syncedEver,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$LocalPlaylistsTableUpdateCompanionBuilder = LocalPlaylistsCompanion
    Function({
  Value<String> id,
  Value<int?> remoteId,
  Value<String> name,
  Value<String> description,
  Value<String> coverUrl,
  Value<String?> coverPicId,
  Value<String?> coverSource,
  Value<bool> isPublic,
  Value<bool> deleted,
  Value<bool> isSynced,
  Value<bool> syncedEver,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$LocalPlaylistsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalPlaylistsTable, LocalPlaylist> {
  $$LocalPlaylistsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LocalPlaylistSongsTable, List<LocalPlaylistSong>>
      _localPlaylistSongsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.localPlaylistSongs,
              aliasName:
                  'local_playlists__id__local_playlist_songs__playlist_id');

  $$LocalPlaylistSongsTableProcessedTableManager get localPlaylistSongsRefs {
    final manager = $$LocalPlaylistSongsTableTableManager(
            $_db, $_db.localPlaylistSongs)
        .filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_localPlaylistSongsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LocalPlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPlaylistsTable> {
  $$LocalPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverPicId => $composableBuilder(
      column: $table.coverPicId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverSource => $composableBuilder(
      column: $table.coverSource, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPublic => $composableBuilder(
      column: $table.isPublic, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get syncedEver => $composableBuilder(
      column: $table.syncedEver, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> localPlaylistSongsRefs(
      Expression<bool> Function($$LocalPlaylistSongsTableFilterComposer f) f) {
    final $$LocalPlaylistSongsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localPlaylistSongs,
        getReferencedColumn: (t) => t.playlistId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalPlaylistSongsTableFilterComposer(
              $db: $db,
              $table: $db.localPlaylistSongs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LocalPlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPlaylistsTable> {
  $$LocalPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverPicId => $composableBuilder(
      column: $table.coverPicId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverSource => $composableBuilder(
      column: $table.coverSource, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPublic => $composableBuilder(
      column: $table.isPublic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get syncedEver => $composableBuilder(
      column: $table.syncedEver, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalPlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPlaylistsTable> {
  $$LocalPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get coverPicId => $composableBuilder(
      column: $table.coverPicId, builder: (column) => column);

  GeneratedColumn<String> get coverSource => $composableBuilder(
      column: $table.coverSource, builder: (column) => column);

  GeneratedColumn<bool> get isPublic =>
      $composableBuilder(column: $table.isPublic, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get syncedEver => $composableBuilder(
      column: $table.syncedEver, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> localPlaylistSongsRefs<T extends Object>(
      Expression<T> Function($$LocalPlaylistSongsTableAnnotationComposer a) f) {
    final $$LocalPlaylistSongsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.localPlaylistSongs,
            getReferencedColumn: (t) => t.playlistId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$LocalPlaylistSongsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.localPlaylistSongs,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$LocalPlaylistsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalPlaylistsTable,
    LocalPlaylist,
    $$LocalPlaylistsTableFilterComposer,
    $$LocalPlaylistsTableOrderingComposer,
    $$LocalPlaylistsTableAnnotationComposer,
    $$LocalPlaylistsTableCreateCompanionBuilder,
    $$LocalPlaylistsTableUpdateCompanionBuilder,
    (LocalPlaylist, $$LocalPlaylistsTableReferences),
    LocalPlaylist,
    PrefetchHooks Function({bool localPlaylistSongsRefs})> {
  $$LocalPlaylistsTableTableManager(
      _$AppDatabase db, $LocalPlaylistsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int?> remoteId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> coverUrl = const Value.absent(),
            Value<String?> coverPicId = const Value.absent(),
            Value<String?> coverSource = const Value.absent(),
            Value<bool> isPublic = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<bool> syncedEver = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPlaylistsCompanion(
            id: id,
            remoteId: remoteId,
            name: name,
            description: description,
            coverUrl: coverUrl,
            coverPicId: coverPicId,
            coverSource: coverSource,
            isPublic: isPublic,
            deleted: deleted,
            isSynced: isSynced,
            syncedEver: syncedEver,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<int?> remoteId = const Value.absent(),
            required String name,
            Value<String> description = const Value.absent(),
            Value<String> coverUrl = const Value.absent(),
            Value<String?> coverPicId = const Value.absent(),
            Value<String?> coverSource = const Value.absent(),
            Value<bool> isPublic = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<bool> syncedEver = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPlaylistsCompanion.insert(
            id: id,
            remoteId: remoteId,
            name: name,
            description: description,
            coverUrl: coverUrl,
            coverPicId: coverPicId,
            coverSource: coverSource,
            isPublic: isPublic,
            deleted: deleted,
            isSynced: isSynced,
            syncedEver: syncedEver,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LocalPlaylistsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({localPlaylistSongsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (localPlaylistSongsRefs) db.localPlaylistSongs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localPlaylistSongsRefs)
                    await $_getPrefetchedData<LocalPlaylist,
                            $LocalPlaylistsTable, LocalPlaylistSong>(
                        currentTable: table,
                        referencedTable: $$LocalPlaylistsTableReferences
                            ._localPlaylistSongsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalPlaylistsTableReferences(db, table, p0)
                                .localPlaylistSongsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.playlistId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$LocalPlaylistsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalPlaylistsTable,
    LocalPlaylist,
    $$LocalPlaylistsTableFilterComposer,
    $$LocalPlaylistsTableOrderingComposer,
    $$LocalPlaylistsTableAnnotationComposer,
    $$LocalPlaylistsTableCreateCompanionBuilder,
    $$LocalPlaylistsTableUpdateCompanionBuilder,
    (LocalPlaylist, $$LocalPlaylistsTableReferences),
    LocalPlaylist,
    PrefetchHooks Function({bool localPlaylistSongsRefs})>;
typedef $$LocalPlaylistSongsTableCreateCompanionBuilder
    = LocalPlaylistSongsCompanion Function({
  Value<int> id,
  required String playlistId,
  required String songId,
  required String source,
  required String songName,
  required String artist,
  Value<String> album,
  Value<String?> coverUrl,
  Value<String?> picId,
  Value<String?> lyricId,
  Value<int> sortOrder,
  Value<int?> remoteId,
  Value<bool> deleted,
  Value<bool> isSynced,
  Value<bool> syncedEver,
  Value<DateTime> createdAt,
});
typedef $$LocalPlaylistSongsTableUpdateCompanionBuilder
    = LocalPlaylistSongsCompanion Function({
  Value<int> id,
  Value<String> playlistId,
  Value<String> songId,
  Value<String> source,
  Value<String> songName,
  Value<String> artist,
  Value<String> album,
  Value<String?> coverUrl,
  Value<String?> picId,
  Value<String?> lyricId,
  Value<int> sortOrder,
  Value<int?> remoteId,
  Value<bool> deleted,
  Value<bool> isSynced,
  Value<bool> syncedEver,
  Value<DateTime> createdAt,
});

final class $$LocalPlaylistSongsTableReferences extends BaseReferences<
    _$AppDatabase, $LocalPlaylistSongsTable, LocalPlaylistSong> {
  $$LocalPlaylistSongsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalPlaylistsTable _playlistIdTable(_$AppDatabase db) => db
      .localPlaylists
      .createAlias('local_playlist_songs__playlist_id__local_playlists__id');

  $$LocalPlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$LocalPlaylistsTableTableManager($_db, $_db.localPlaylists)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocalPlaylistSongsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPlaylistSongsTable> {
  $$LocalPlaylistSongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get songId => $composableBuilder(
      column: $table.songId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get songName => $composableBuilder(
      column: $table.songName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get picId => $composableBuilder(
      column: $table.picId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lyricId => $composableBuilder(
      column: $table.lyricId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get syncedEver => $composableBuilder(
      column: $table.syncedEver, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$LocalPlaylistsTableFilterComposer get playlistId {
    final $$LocalPlaylistsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.localPlaylists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalPlaylistsTableFilterComposer(
              $db: $db,
              $table: $db.localPlaylists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalPlaylistSongsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPlaylistSongsTable> {
  $$LocalPlaylistSongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get songId => $composableBuilder(
      column: $table.songId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get songName => $composableBuilder(
      column: $table.songName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get picId => $composableBuilder(
      column: $table.picId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lyricId => $composableBuilder(
      column: $table.lyricId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get syncedEver => $composableBuilder(
      column: $table.syncedEver, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$LocalPlaylistsTableOrderingComposer get playlistId {
    final $$LocalPlaylistsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.localPlaylists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalPlaylistsTableOrderingComposer(
              $db: $db,
              $table: $db.localPlaylists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalPlaylistSongsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPlaylistSongsTable> {
  $$LocalPlaylistSongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get songName =>
      $composableBuilder(column: $table.songName, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get picId =>
      $composableBuilder(column: $table.picId, builder: (column) => column);

  GeneratedColumn<String> get lyricId =>
      $composableBuilder(column: $table.lyricId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get syncedEver => $composableBuilder(
      column: $table.syncedEver, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LocalPlaylistsTableAnnotationComposer get playlistId {
    final $$LocalPlaylistsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.localPlaylists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalPlaylistsTableAnnotationComposer(
              $db: $db,
              $table: $db.localPlaylists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalPlaylistSongsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalPlaylistSongsTable,
    LocalPlaylistSong,
    $$LocalPlaylistSongsTableFilterComposer,
    $$LocalPlaylistSongsTableOrderingComposer,
    $$LocalPlaylistSongsTableAnnotationComposer,
    $$LocalPlaylistSongsTableCreateCompanionBuilder,
    $$LocalPlaylistSongsTableUpdateCompanionBuilder,
    (LocalPlaylistSong, $$LocalPlaylistSongsTableReferences),
    LocalPlaylistSong,
    PrefetchHooks Function({bool playlistId})> {
  $$LocalPlaylistSongsTableTableManager(
      _$AppDatabase db, $LocalPlaylistSongsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPlaylistSongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPlaylistSongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPlaylistSongsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> playlistId = const Value.absent(),
            Value<String> songId = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> songName = const Value.absent(),
            Value<String> artist = const Value.absent(),
            Value<String> album = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> picId = const Value.absent(),
            Value<String?> lyricId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int?> remoteId = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<bool> syncedEver = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              LocalPlaylistSongsCompanion(
            id: id,
            playlistId: playlistId,
            songId: songId,
            source: source,
            songName: songName,
            artist: artist,
            album: album,
            coverUrl: coverUrl,
            picId: picId,
            lyricId: lyricId,
            sortOrder: sortOrder,
            remoteId: remoteId,
            deleted: deleted,
            isSynced: isSynced,
            syncedEver: syncedEver,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String playlistId,
            required String songId,
            required String source,
            required String songName,
            required String artist,
            Value<String> album = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> picId = const Value.absent(),
            Value<String?> lyricId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int?> remoteId = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<bool> syncedEver = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              LocalPlaylistSongsCompanion.insert(
            id: id,
            playlistId: playlistId,
            songId: songId,
            source: source,
            songName: songName,
            artist: artist,
            album: album,
            coverUrl: coverUrl,
            picId: picId,
            lyricId: lyricId,
            sortOrder: sortOrder,
            remoteId: remoteId,
            deleted: deleted,
            isSynced: isSynced,
            syncedEver: syncedEver,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LocalPlaylistSongsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (playlistId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.playlistId,
                    referencedTable: $$LocalPlaylistSongsTableReferences
                        ._playlistIdTable(db),
                    referencedColumn: $$LocalPlaylistSongsTableReferences
                        ._playlistIdTable(db)
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
        ));
}

typedef $$LocalPlaylistSongsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalPlaylistSongsTable,
    LocalPlaylistSong,
    $$LocalPlaylistSongsTableFilterComposer,
    $$LocalPlaylistSongsTableOrderingComposer,
    $$LocalPlaylistSongsTableAnnotationComposer,
    $$LocalPlaylistSongsTableCreateCompanionBuilder,
    $$LocalPlaylistSongsTableUpdateCompanionBuilder,
    (LocalPlaylistSong, $$LocalPlaylistSongsTableReferences),
    LocalPlaylistSong,
    PrefetchHooks Function({bool playlistId})>;
typedef $$LocalPlayRecordsTableCreateCompanionBuilder
    = LocalPlayRecordsCompanion Function({
  Value<int> id,
  required String songId,
  Value<String> source,
  Value<String> songName,
  Value<String> artist,
  Value<String?> coverUrl,
  Value<String?> picId,
  Value<String> album,
  Value<String?> lyricId,
  Value<DateTime> playedAt,
  Value<bool> isSynced,
  Value<int> attemptCount,
});
typedef $$LocalPlayRecordsTableUpdateCompanionBuilder
    = LocalPlayRecordsCompanion Function({
  Value<int> id,
  Value<String> songId,
  Value<String> source,
  Value<String> songName,
  Value<String> artist,
  Value<String?> coverUrl,
  Value<String?> picId,
  Value<String> album,
  Value<String?> lyricId,
  Value<DateTime> playedAt,
  Value<bool> isSynced,
  Value<int> attemptCount,
});

class $$LocalPlayRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPlayRecordsTable> {
  $$LocalPlayRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get songId => $composableBuilder(
      column: $table.songId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get songName => $composableBuilder(
      column: $table.songName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get picId => $composableBuilder(
      column: $table.picId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lyricId => $composableBuilder(
      column: $table.lyricId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
      column: $table.playedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));
}

class $$LocalPlayRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPlayRecordsTable> {
  $$LocalPlayRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get songId => $composableBuilder(
      column: $table.songId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get songName => $composableBuilder(
      column: $table.songName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get picId => $composableBuilder(
      column: $table.picId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lyricId => $composableBuilder(
      column: $table.lyricId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
      column: $table.playedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));
}

class $$LocalPlayRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPlayRecordsTable> {
  $$LocalPlayRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get songName =>
      $composableBuilder(column: $table.songName, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get picId =>
      $composableBuilder(column: $table.picId, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get lyricId =>
      $composableBuilder(column: $table.lyricId, builder: (column) => column);

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);
}

class $$LocalPlayRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalPlayRecordsTable,
    LocalPlayRecord,
    $$LocalPlayRecordsTableFilterComposer,
    $$LocalPlayRecordsTableOrderingComposer,
    $$LocalPlayRecordsTableAnnotationComposer,
    $$LocalPlayRecordsTableCreateCompanionBuilder,
    $$LocalPlayRecordsTableUpdateCompanionBuilder,
    (
      LocalPlayRecord,
      BaseReferences<_$AppDatabase, $LocalPlayRecordsTable, LocalPlayRecord>
    ),
    LocalPlayRecord,
    PrefetchHooks Function()> {
  $$LocalPlayRecordsTableTableManager(
      _$AppDatabase db, $LocalPlayRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPlayRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPlayRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPlayRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> songId = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> songName = const Value.absent(),
            Value<String> artist = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> picId = const Value.absent(),
            Value<String> album = const Value.absent(),
            Value<String?> lyricId = const Value.absent(),
            Value<DateTime> playedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
          }) =>
              LocalPlayRecordsCompanion(
            id: id,
            songId: songId,
            source: source,
            songName: songName,
            artist: artist,
            coverUrl: coverUrl,
            picId: picId,
            album: album,
            lyricId: lyricId,
            playedAt: playedAt,
            isSynced: isSynced,
            attemptCount: attemptCount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String songId,
            Value<String> source = const Value.absent(),
            Value<String> songName = const Value.absent(),
            Value<String> artist = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> picId = const Value.absent(),
            Value<String> album = const Value.absent(),
            Value<String?> lyricId = const Value.absent(),
            Value<DateTime> playedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
          }) =>
              LocalPlayRecordsCompanion.insert(
            id: id,
            songId: songId,
            source: source,
            songName: songName,
            artist: artist,
            coverUrl: coverUrl,
            picId: picId,
            album: album,
            lyricId: lyricId,
            playedAt: playedAt,
            isSynced: isSynced,
            attemptCount: attemptCount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalPlayRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalPlayRecordsTable,
    LocalPlayRecord,
    $$LocalPlayRecordsTableFilterComposer,
    $$LocalPlayRecordsTableOrderingComposer,
    $$LocalPlayRecordsTableAnnotationComposer,
    $$LocalPlayRecordsTableCreateCompanionBuilder,
    $$LocalPlayRecordsTableUpdateCompanionBuilder,
    (
      LocalPlayRecord,
      BaseReferences<_$AppDatabase, $LocalPlayRecordsTable, LocalPlayRecord>
    ),
    LocalPlayRecord,
    PrefetchHooks Function()>;
typedef $$LocalSearchHistoryTableCreateCompanionBuilder
    = LocalSearchHistoryCompanion Function({
  Value<int> id,
  required String keyword,
  Value<DateTime> createdAt,
});
typedef $$LocalSearchHistoryTableUpdateCompanionBuilder
    = LocalSearchHistoryCompanion Function({
  Value<int> id,
  Value<String> keyword,
  Value<DateTime> createdAt,
});

class $$LocalSearchHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSearchHistoryTable> {
  $$LocalSearchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyword => $composableBuilder(
      column: $table.keyword, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$LocalSearchHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSearchHistoryTable> {
  $$LocalSearchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyword => $composableBuilder(
      column: $table.keyword, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalSearchHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSearchHistoryTable> {
  $$LocalSearchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get keyword =>
      $composableBuilder(column: $table.keyword, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalSearchHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalSearchHistoryTable,
    LocalSearchHistoryData,
    $$LocalSearchHistoryTableFilterComposer,
    $$LocalSearchHistoryTableOrderingComposer,
    $$LocalSearchHistoryTableAnnotationComposer,
    $$LocalSearchHistoryTableCreateCompanionBuilder,
    $$LocalSearchHistoryTableUpdateCompanionBuilder,
    (
      LocalSearchHistoryData,
      BaseReferences<_$AppDatabase, $LocalSearchHistoryTable,
          LocalSearchHistoryData>
    ),
    LocalSearchHistoryData,
    PrefetchHooks Function()> {
  $$LocalSearchHistoryTableTableManager(
      _$AppDatabase db, $LocalSearchHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSearchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSearchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSearchHistoryTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> keyword = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              LocalSearchHistoryCompanion(
            id: id,
            keyword: keyword,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String keyword,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              LocalSearchHistoryCompanion.insert(
            id: id,
            keyword: keyword,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalSearchHistoryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalSearchHistoryTable,
    LocalSearchHistoryData,
    $$LocalSearchHistoryTableFilterComposer,
    $$LocalSearchHistoryTableOrderingComposer,
    $$LocalSearchHistoryTableAnnotationComposer,
    $$LocalSearchHistoryTableCreateCompanionBuilder,
    $$LocalSearchHistoryTableUpdateCompanionBuilder,
    (
      LocalSearchHistoryData,
      BaseReferences<_$AppDatabase, $LocalSearchHistoryTable,
          LocalSearchHistoryData>
    ),
    LocalSearchHistoryData,
    PrefetchHooks Function()>;
typedef $$LocalPlaySessionsTableCreateCompanionBuilder
    = LocalPlaySessionsCompanion Function({
  Value<int> id,
  Value<String?> queueJson,
  Value<int> currentIndex,
  Value<int> positionMs,
  Value<String> playMode,
  Value<DateTime> updatedAt,
});
typedef $$LocalPlaySessionsTableUpdateCompanionBuilder
    = LocalPlaySessionsCompanion Function({
  Value<int> id,
  Value<String?> queueJson,
  Value<int> currentIndex,
  Value<int> positionMs,
  Value<String> playMode,
  Value<DateTime> updatedAt,
});

class $$LocalPlaySessionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPlaySessionsTable> {
  $$LocalPlaySessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get queueJson => $composableBuilder(
      column: $table.queueJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentIndex => $composableBuilder(
      column: $table.currentIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get positionMs => $composableBuilder(
      column: $table.positionMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get playMode => $composableBuilder(
      column: $table.playMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalPlaySessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPlaySessionsTable> {
  $$LocalPlaySessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get queueJson => $composableBuilder(
      column: $table.queueJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentIndex => $composableBuilder(
      column: $table.currentIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get positionMs => $composableBuilder(
      column: $table.positionMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get playMode => $composableBuilder(
      column: $table.playMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalPlaySessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPlaySessionsTable> {
  $$LocalPlaySessionsTableAnnotationComposer({
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

  GeneratedColumn<int> get currentIndex => $composableBuilder(
      column: $table.currentIndex, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(
      column: $table.positionMs, builder: (column) => column);

  GeneratedColumn<String> get playMode =>
      $composableBuilder(column: $table.playMode, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalPlaySessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalPlaySessionsTable,
    LocalPlaySession,
    $$LocalPlaySessionsTableFilterComposer,
    $$LocalPlaySessionsTableOrderingComposer,
    $$LocalPlaySessionsTableAnnotationComposer,
    $$LocalPlaySessionsTableCreateCompanionBuilder,
    $$LocalPlaySessionsTableUpdateCompanionBuilder,
    (
      LocalPlaySession,
      BaseReferences<_$AppDatabase, $LocalPlaySessionsTable, LocalPlaySession>
    ),
    LocalPlaySession,
    PrefetchHooks Function()> {
  $$LocalPlaySessionsTableTableManager(
      _$AppDatabase db, $LocalPlaySessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPlaySessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPlaySessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPlaySessionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> queueJson = const Value.absent(),
            Value<int> currentIndex = const Value.absent(),
            Value<int> positionMs = const Value.absent(),
            Value<String> playMode = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              LocalPlaySessionsCompanion(
            id: id,
            queueJson: queueJson,
            currentIndex: currentIndex,
            positionMs: positionMs,
            playMode: playMode,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> queueJson = const Value.absent(),
            Value<int> currentIndex = const Value.absent(),
            Value<int> positionMs = const Value.absent(),
            Value<String> playMode = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              LocalPlaySessionsCompanion.insert(
            id: id,
            queueJson: queueJson,
            currentIndex: currentIndex,
            positionMs: positionMs,
            playMode: playMode,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalPlaySessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalPlaySessionsTable,
    LocalPlaySession,
    $$LocalPlaySessionsTableFilterComposer,
    $$LocalPlaySessionsTableOrderingComposer,
    $$LocalPlaySessionsTableAnnotationComposer,
    $$LocalPlaySessionsTableCreateCompanionBuilder,
    $$LocalPlaySessionsTableUpdateCompanionBuilder,
    (
      LocalPlaySession,
      BaseReferences<_$AppDatabase, $LocalPlaySessionsTable, LocalPlaySession>
    ),
    LocalPlaySession,
    PrefetchHooks Function()>;
typedef $$LocalSettingsTableCreateCompanionBuilder = LocalSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$LocalSettingsTableUpdateCompanionBuilder = LocalSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$LocalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$LocalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$LocalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
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

class $$LocalSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalSettingsTable,
    LocalSetting,
    $$LocalSettingsTableFilterComposer,
    $$LocalSettingsTableOrderingComposer,
    $$LocalSettingsTableAnnotationComposer,
    $$LocalSettingsTableCreateCompanionBuilder,
    $$LocalSettingsTableUpdateCompanionBuilder,
    (
      LocalSetting,
      BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>
    ),
    LocalSetting,
    PrefetchHooks Function()> {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalSettingsTable,
    LocalSetting,
    $$LocalSettingsTableFilterComposer,
    $$LocalSettingsTableOrderingComposer,
    $$LocalSettingsTableAnnotationComposer,
    $$LocalSettingsTableCreateCompanionBuilder,
    $$LocalSettingsTableUpdateCompanionBuilder,
    (
      LocalSetting,
      BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>
    ),
    LocalSetting,
    PrefetchHooks Function()>;
typedef $$LocalSongMetaTableCreateCompanionBuilder = LocalSongMetaCompanion
    Function({
  required String songId,
  required String source,
  Value<String> name,
  Value<String> artist,
  Value<String> album,
  Value<String?> picId,
  Value<String?> lyricId,
  Value<String?> coverUrl,
  Value<String?> lyrics,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$LocalSongMetaTableUpdateCompanionBuilder = LocalSongMetaCompanion
    Function({
  Value<String> songId,
  Value<String> source,
  Value<String> name,
  Value<String> artist,
  Value<String> album,
  Value<String?> picId,
  Value<String?> lyricId,
  Value<String?> coverUrl,
  Value<String?> lyrics,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalSongMetaTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSongMetaTable> {
  $$LocalSongMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get songId => $composableBuilder(
      column: $table.songId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get picId => $composableBuilder(
      column: $table.picId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lyricId => $composableBuilder(
      column: $table.lyricId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lyrics => $composableBuilder(
      column: $table.lyrics, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalSongMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSongMetaTable> {
  $$LocalSongMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get songId => $composableBuilder(
      column: $table.songId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get picId => $composableBuilder(
      column: $table.picId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lyricId => $composableBuilder(
      column: $table.lyricId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lyrics => $composableBuilder(
      column: $table.lyrics, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalSongMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSongMetaTable> {
  $$LocalSongMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get picId =>
      $composableBuilder(column: $table.picId, builder: (column) => column);

  GeneratedColumn<String> get lyricId =>
      $composableBuilder(column: $table.lyricId, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get lyrics =>
      $composableBuilder(column: $table.lyrics, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalSongMetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalSongMetaTable,
    LocalSongMetaData,
    $$LocalSongMetaTableFilterComposer,
    $$LocalSongMetaTableOrderingComposer,
    $$LocalSongMetaTableAnnotationComposer,
    $$LocalSongMetaTableCreateCompanionBuilder,
    $$LocalSongMetaTableUpdateCompanionBuilder,
    (
      LocalSongMetaData,
      BaseReferences<_$AppDatabase, $LocalSongMetaTable, LocalSongMetaData>
    ),
    LocalSongMetaData,
    PrefetchHooks Function()> {
  $$LocalSongMetaTableTableManager(_$AppDatabase db, $LocalSongMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSongMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSongMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSongMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> songId = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> artist = const Value.absent(),
            Value<String> album = const Value.absent(),
            Value<String?> picId = const Value.absent(),
            Value<String?> lyricId = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> lyrics = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSongMetaCompanion(
            songId: songId,
            source: source,
            name: name,
            artist: artist,
            album: album,
            picId: picId,
            lyricId: lyricId,
            coverUrl: coverUrl,
            lyrics: lyrics,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String songId,
            required String source,
            Value<String> name = const Value.absent(),
            Value<String> artist = const Value.absent(),
            Value<String> album = const Value.absent(),
            Value<String?> picId = const Value.absent(),
            Value<String?> lyricId = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> lyrics = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSongMetaCompanion.insert(
            songId: songId,
            source: source,
            name: name,
            artist: artist,
            album: album,
            picId: picId,
            lyricId: lyricId,
            coverUrl: coverUrl,
            lyrics: lyrics,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalSongMetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalSongMetaTable,
    LocalSongMetaData,
    $$LocalSongMetaTableFilterComposer,
    $$LocalSongMetaTableOrderingComposer,
    $$LocalSongMetaTableAnnotationComposer,
    $$LocalSongMetaTableCreateCompanionBuilder,
    $$LocalSongMetaTableUpdateCompanionBuilder,
    (
      LocalSongMetaData,
      BaseReferences<_$AppDatabase, $LocalSongMetaTable, LocalSongMetaData>
    ),
    LocalSongMetaData,
    PrefetchHooks Function()>;
typedef $$LocalPlaylistFollowsTableCreateCompanionBuilder
    = LocalPlaylistFollowsCompanion Function({
  Value<int> playlistId,
  Value<String> name,
  Value<String> description,
  Value<String> coverUrl,
  Value<String?> coverPicId,
  Value<String?> coverSource,
  Value<String> ownerNickname,
  Value<String> ownerAvatarUrl,
  Value<int> songCount,
  Value<bool> deleted,
  Value<bool> isSynced,
  Value<bool> syncedEver,
  Value<DateTime> createdAt,
});
typedef $$LocalPlaylistFollowsTableUpdateCompanionBuilder
    = LocalPlaylistFollowsCompanion Function({
  Value<int> playlistId,
  Value<String> name,
  Value<String> description,
  Value<String> coverUrl,
  Value<String?> coverPicId,
  Value<String?> coverSource,
  Value<String> ownerNickname,
  Value<String> ownerAvatarUrl,
  Value<int> songCount,
  Value<bool> deleted,
  Value<bool> isSynced,
  Value<bool> syncedEver,
  Value<DateTime> createdAt,
});

class $$LocalPlaylistFollowsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPlaylistFollowsTable> {
  $$LocalPlaylistFollowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get playlistId => $composableBuilder(
      column: $table.playlistId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverPicId => $composableBuilder(
      column: $table.coverPicId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverSource => $composableBuilder(
      column: $table.coverSource, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerNickname => $composableBuilder(
      column: $table.ownerNickname, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerAvatarUrl => $composableBuilder(
      column: $table.ownerAvatarUrl,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get songCount => $composableBuilder(
      column: $table.songCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get syncedEver => $composableBuilder(
      column: $table.syncedEver, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$LocalPlaylistFollowsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPlaylistFollowsTable> {
  $$LocalPlaylistFollowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get playlistId => $composableBuilder(
      column: $table.playlistId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverPicId => $composableBuilder(
      column: $table.coverPicId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverSource => $composableBuilder(
      column: $table.coverSource, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerNickname => $composableBuilder(
      column: $table.ownerNickname,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerAvatarUrl => $composableBuilder(
      column: $table.ownerAvatarUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get songCount => $composableBuilder(
      column: $table.songCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get syncedEver => $composableBuilder(
      column: $table.syncedEver, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalPlaylistFollowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPlaylistFollowsTable> {
  $$LocalPlaylistFollowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get playlistId => $composableBuilder(
      column: $table.playlistId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get coverPicId => $composableBuilder(
      column: $table.coverPicId, builder: (column) => column);

  GeneratedColumn<String> get coverSource => $composableBuilder(
      column: $table.coverSource, builder: (column) => column);

  GeneratedColumn<String> get ownerNickname => $composableBuilder(
      column: $table.ownerNickname, builder: (column) => column);

  GeneratedColumn<String> get ownerAvatarUrl => $composableBuilder(
      column: $table.ownerAvatarUrl, builder: (column) => column);

  GeneratedColumn<int> get songCount =>
      $composableBuilder(column: $table.songCount, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get syncedEver => $composableBuilder(
      column: $table.syncedEver, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalPlaylistFollowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalPlaylistFollowsTable,
    LocalPlaylistFollow,
    $$LocalPlaylistFollowsTableFilterComposer,
    $$LocalPlaylistFollowsTableOrderingComposer,
    $$LocalPlaylistFollowsTableAnnotationComposer,
    $$LocalPlaylistFollowsTableCreateCompanionBuilder,
    $$LocalPlaylistFollowsTableUpdateCompanionBuilder,
    (
      LocalPlaylistFollow,
      BaseReferences<_$AppDatabase, $LocalPlaylistFollowsTable,
          LocalPlaylistFollow>
    ),
    LocalPlaylistFollow,
    PrefetchHooks Function()> {
  $$LocalPlaylistFollowsTableTableManager(
      _$AppDatabase db, $LocalPlaylistFollowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPlaylistFollowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPlaylistFollowsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPlaylistFollowsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> playlistId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> coverUrl = const Value.absent(),
            Value<String?> coverPicId = const Value.absent(),
            Value<String?> coverSource = const Value.absent(),
            Value<String> ownerNickname = const Value.absent(),
            Value<String> ownerAvatarUrl = const Value.absent(),
            Value<int> songCount = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<bool> syncedEver = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              LocalPlaylistFollowsCompanion(
            playlistId: playlistId,
            name: name,
            description: description,
            coverUrl: coverUrl,
            coverPicId: coverPicId,
            coverSource: coverSource,
            ownerNickname: ownerNickname,
            ownerAvatarUrl: ownerAvatarUrl,
            songCount: songCount,
            deleted: deleted,
            isSynced: isSynced,
            syncedEver: syncedEver,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> playlistId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> coverUrl = const Value.absent(),
            Value<String?> coverPicId = const Value.absent(),
            Value<String?> coverSource = const Value.absent(),
            Value<String> ownerNickname = const Value.absent(),
            Value<String> ownerAvatarUrl = const Value.absent(),
            Value<int> songCount = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<bool> syncedEver = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              LocalPlaylistFollowsCompanion.insert(
            playlistId: playlistId,
            name: name,
            description: description,
            coverUrl: coverUrl,
            coverPicId: coverPicId,
            coverSource: coverSource,
            ownerNickname: ownerNickname,
            ownerAvatarUrl: ownerAvatarUrl,
            songCount: songCount,
            deleted: deleted,
            isSynced: isSynced,
            syncedEver: syncedEver,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalPlaylistFollowsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $LocalPlaylistFollowsTable,
        LocalPlaylistFollow,
        $$LocalPlaylistFollowsTableFilterComposer,
        $$LocalPlaylistFollowsTableOrderingComposer,
        $$LocalPlaylistFollowsTableAnnotationComposer,
        $$LocalPlaylistFollowsTableCreateCompanionBuilder,
        $$LocalPlaylistFollowsTableUpdateCompanionBuilder,
        (
          LocalPlaylistFollow,
          BaseReferences<_$AppDatabase, $LocalPlaylistFollowsTable,
              LocalPlaylistFollow>
        ),
        LocalPlaylistFollow,
        PrefetchHooks Function()>;
typedef $$LocalRecommendPlaylistsTableCreateCompanionBuilder
    = LocalRecommendPlaylistsCompanion Function({
  Value<int> remoteId,
  required String name,
  Value<String> description,
  Value<String> coverUrl,
  Value<String?> coverPicId,
  Value<String?> coverSource,
  Value<String> type,
  Value<int> songCount,
  Value<int> playCount,
  Value<String> ownerNickname,
  Value<String> ownerAvatarUrl,
  Value<int> orderIndex,
});
typedef $$LocalRecommendPlaylistsTableUpdateCompanionBuilder
    = LocalRecommendPlaylistsCompanion Function({
  Value<int> remoteId,
  Value<String> name,
  Value<String> description,
  Value<String> coverUrl,
  Value<String?> coverPicId,
  Value<String?> coverSource,
  Value<String> type,
  Value<int> songCount,
  Value<int> playCount,
  Value<String> ownerNickname,
  Value<String> ownerAvatarUrl,
  Value<int> orderIndex,
});

class $$LocalRecommendPlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalRecommendPlaylistsTable> {
  $$LocalRecommendPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverPicId => $composableBuilder(
      column: $table.coverPicId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverSource => $composableBuilder(
      column: $table.coverSource, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get songCount => $composableBuilder(
      column: $table.songCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playCount => $composableBuilder(
      column: $table.playCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerNickname => $composableBuilder(
      column: $table.ownerNickname, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerAvatarUrl => $composableBuilder(
      column: $table.ownerAvatarUrl,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));
}

class $$LocalRecommendPlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalRecommendPlaylistsTable> {
  $$LocalRecommendPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverPicId => $composableBuilder(
      column: $table.coverPicId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverSource => $composableBuilder(
      column: $table.coverSource, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get songCount => $composableBuilder(
      column: $table.songCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playCount => $composableBuilder(
      column: $table.playCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerNickname => $composableBuilder(
      column: $table.ownerNickname,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerAvatarUrl => $composableBuilder(
      column: $table.ownerAvatarUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));
}

class $$LocalRecommendPlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalRecommendPlaylistsTable> {
  $$LocalRecommendPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get coverPicId => $composableBuilder(
      column: $table.coverPicId, builder: (column) => column);

  GeneratedColumn<String> get coverSource => $composableBuilder(
      column: $table.coverSource, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get songCount =>
      $composableBuilder(column: $table.songCount, builder: (column) => column);

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  GeneratedColumn<String> get ownerNickname => $composableBuilder(
      column: $table.ownerNickname, builder: (column) => column);

  GeneratedColumn<String> get ownerAvatarUrl => $composableBuilder(
      column: $table.ownerAvatarUrl, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);
}

class $$LocalRecommendPlaylistsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalRecommendPlaylistsTable,
    LocalRecommendPlaylist,
    $$LocalRecommendPlaylistsTableFilterComposer,
    $$LocalRecommendPlaylistsTableOrderingComposer,
    $$LocalRecommendPlaylistsTableAnnotationComposer,
    $$LocalRecommendPlaylistsTableCreateCompanionBuilder,
    $$LocalRecommendPlaylistsTableUpdateCompanionBuilder,
    (
      LocalRecommendPlaylist,
      BaseReferences<_$AppDatabase, $LocalRecommendPlaylistsTable,
          LocalRecommendPlaylist>
    ),
    LocalRecommendPlaylist,
    PrefetchHooks Function()> {
  $$LocalRecommendPlaylistsTableTableManager(
      _$AppDatabase db, $LocalRecommendPlaylistsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalRecommendPlaylistsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalRecommendPlaylistsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalRecommendPlaylistsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> remoteId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> coverUrl = const Value.absent(),
            Value<String?> coverPicId = const Value.absent(),
            Value<String?> coverSource = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> songCount = const Value.absent(),
            Value<int> playCount = const Value.absent(),
            Value<String> ownerNickname = const Value.absent(),
            Value<String> ownerAvatarUrl = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
          }) =>
              LocalRecommendPlaylistsCompanion(
            remoteId: remoteId,
            name: name,
            description: description,
            coverUrl: coverUrl,
            coverPicId: coverPicId,
            coverSource: coverSource,
            type: type,
            songCount: songCount,
            playCount: playCount,
            ownerNickname: ownerNickname,
            ownerAvatarUrl: ownerAvatarUrl,
            orderIndex: orderIndex,
          ),
          createCompanionCallback: ({
            Value<int> remoteId = const Value.absent(),
            required String name,
            Value<String> description = const Value.absent(),
            Value<String> coverUrl = const Value.absent(),
            Value<String?> coverPicId = const Value.absent(),
            Value<String?> coverSource = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> songCount = const Value.absent(),
            Value<int> playCount = const Value.absent(),
            Value<String> ownerNickname = const Value.absent(),
            Value<String> ownerAvatarUrl = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
          }) =>
              LocalRecommendPlaylistsCompanion.insert(
            remoteId: remoteId,
            name: name,
            description: description,
            coverUrl: coverUrl,
            coverPicId: coverPicId,
            coverSource: coverSource,
            type: type,
            songCount: songCount,
            playCount: playCount,
            ownerNickname: ownerNickname,
            ownerAvatarUrl: ownerAvatarUrl,
            orderIndex: orderIndex,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalRecommendPlaylistsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $LocalRecommendPlaylistsTable,
        LocalRecommendPlaylist,
        $$LocalRecommendPlaylistsTableFilterComposer,
        $$LocalRecommendPlaylistsTableOrderingComposer,
        $$LocalRecommendPlaylistsTableAnnotationComposer,
        $$LocalRecommendPlaylistsTableCreateCompanionBuilder,
        $$LocalRecommendPlaylistsTableUpdateCompanionBuilder,
        (
          LocalRecommendPlaylist,
          BaseReferences<_$AppDatabase, $LocalRecommendPlaylistsTable,
              LocalRecommendPlaylist>
        ),
        LocalRecommendPlaylist,
        PrefetchHooks Function()>;
typedef $$LocalRecommendPlaylistSongsTableCreateCompanionBuilder
    = LocalRecommendPlaylistSongsCompanion Function({
  required int playlistRemoteId,
  required String songId,
  Value<String> source,
  required String songName,
  Value<String> artist,
  Value<String> album,
  Value<String?> coverUrl,
  Value<String?> picId,
  Value<String?> lyricId,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$LocalRecommendPlaylistSongsTableUpdateCompanionBuilder
    = LocalRecommendPlaylistSongsCompanion Function({
  Value<int> playlistRemoteId,
  Value<String> songId,
  Value<String> source,
  Value<String> songName,
  Value<String> artist,
  Value<String> album,
  Value<String?> coverUrl,
  Value<String?> picId,
  Value<String?> lyricId,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$LocalRecommendPlaylistSongsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalRecommendPlaylistSongsTable> {
  $$LocalRecommendPlaylistSongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get playlistRemoteId => $composableBuilder(
      column: $table.playlistRemoteId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get songId => $composableBuilder(
      column: $table.songId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get songName => $composableBuilder(
      column: $table.songName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get picId => $composableBuilder(
      column: $table.picId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lyricId => $composableBuilder(
      column: $table.lyricId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$LocalRecommendPlaylistSongsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalRecommendPlaylistSongsTable> {
  $$LocalRecommendPlaylistSongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get playlistRemoteId => $composableBuilder(
      column: $table.playlistRemoteId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get songId => $composableBuilder(
      column: $table.songId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get songName => $composableBuilder(
      column: $table.songName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get picId => $composableBuilder(
      column: $table.picId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lyricId => $composableBuilder(
      column: $table.lyricId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$LocalRecommendPlaylistSongsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalRecommendPlaylistSongsTable> {
  $$LocalRecommendPlaylistSongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get playlistRemoteId => $composableBuilder(
      column: $table.playlistRemoteId, builder: (column) => column);

  GeneratedColumn<String> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get songName =>
      $composableBuilder(column: $table.songName, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get picId =>
      $composableBuilder(column: $table.picId, builder: (column) => column);

  GeneratedColumn<String> get lyricId =>
      $composableBuilder(column: $table.lyricId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$LocalRecommendPlaylistSongsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalRecommendPlaylistSongsTable,
    LocalRecommendPlaylistSong,
    $$LocalRecommendPlaylistSongsTableFilterComposer,
    $$LocalRecommendPlaylistSongsTableOrderingComposer,
    $$LocalRecommendPlaylistSongsTableAnnotationComposer,
    $$LocalRecommendPlaylistSongsTableCreateCompanionBuilder,
    $$LocalRecommendPlaylistSongsTableUpdateCompanionBuilder,
    (
      LocalRecommendPlaylistSong,
      BaseReferences<_$AppDatabase, $LocalRecommendPlaylistSongsTable,
          LocalRecommendPlaylistSong>
    ),
    LocalRecommendPlaylistSong,
    PrefetchHooks Function()> {
  $$LocalRecommendPlaylistSongsTableTableManager(
      _$AppDatabase db, $LocalRecommendPlaylistSongsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalRecommendPlaylistSongsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalRecommendPlaylistSongsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalRecommendPlaylistSongsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> playlistRemoteId = const Value.absent(),
            Value<String> songId = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> songName = const Value.absent(),
            Value<String> artist = const Value.absent(),
            Value<String> album = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> picId = const Value.absent(),
            Value<String?> lyricId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalRecommendPlaylistSongsCompanion(
            playlistRemoteId: playlistRemoteId,
            songId: songId,
            source: source,
            songName: songName,
            artist: artist,
            album: album,
            coverUrl: coverUrl,
            picId: picId,
            lyricId: lyricId,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int playlistRemoteId,
            required String songId,
            Value<String> source = const Value.absent(),
            required String songName,
            Value<String> artist = const Value.absent(),
            Value<String> album = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> picId = const Value.absent(),
            Value<String?> lyricId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalRecommendPlaylistSongsCompanion.insert(
            playlistRemoteId: playlistRemoteId,
            songId: songId,
            source: source,
            songName: songName,
            artist: artist,
            album: album,
            coverUrl: coverUrl,
            picId: picId,
            lyricId: lyricId,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalRecommendPlaylistSongsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $LocalRecommendPlaylistSongsTable,
        LocalRecommendPlaylistSong,
        $$LocalRecommendPlaylistSongsTableFilterComposer,
        $$LocalRecommendPlaylistSongsTableOrderingComposer,
        $$LocalRecommendPlaylistSongsTableAnnotationComposer,
        $$LocalRecommendPlaylistSongsTableCreateCompanionBuilder,
        $$LocalRecommendPlaylistSongsTableUpdateCompanionBuilder,
        (
          LocalRecommendPlaylistSong,
          BaseReferences<_$AppDatabase, $LocalRecommendPlaylistSongsTable,
              LocalRecommendPlaylistSong>
        ),
        LocalRecommendPlaylistSong,
        PrefetchHooks Function()>;
typedef $$LocalPicCoversTableCreateCompanionBuilder = LocalPicCoversCompanion
    Function({
  required String picId,
  required String source,
  required String coverUrl,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$LocalPicCoversTableUpdateCompanionBuilder = LocalPicCoversCompanion
    Function({
  Value<String> picId,
  Value<String> source,
  Value<String> coverUrl,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalPicCoversTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPicCoversTable> {
  $$LocalPicCoversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get picId => $composableBuilder(
      column: $table.picId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalPicCoversTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPicCoversTable> {
  $$LocalPicCoversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get picId => $composableBuilder(
      column: $table.picId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalPicCoversTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPicCoversTable> {
  $$LocalPicCoversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get picId =>
      $composableBuilder(column: $table.picId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalPicCoversTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalPicCoversTable,
    LocalPicCover,
    $$LocalPicCoversTableFilterComposer,
    $$LocalPicCoversTableOrderingComposer,
    $$LocalPicCoversTableAnnotationComposer,
    $$LocalPicCoversTableCreateCompanionBuilder,
    $$LocalPicCoversTableUpdateCompanionBuilder,
    (
      LocalPicCover,
      BaseReferences<_$AppDatabase, $LocalPicCoversTable, LocalPicCover>
    ),
    LocalPicCover,
    PrefetchHooks Function()> {
  $$LocalPicCoversTableTableManager(
      _$AppDatabase db, $LocalPicCoversTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPicCoversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPicCoversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPicCoversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> picId = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> coverUrl = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPicCoversCompanion(
            picId: picId,
            source: source,
            coverUrl: coverUrl,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String picId,
            required String source,
            required String coverUrl,
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPicCoversCompanion.insert(
            picId: picId,
            source: source,
            coverUrl: coverUrl,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalPicCoversTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalPicCoversTable,
    LocalPicCover,
    $$LocalPicCoversTableFilterComposer,
    $$LocalPicCoversTableOrderingComposer,
    $$LocalPicCoversTableAnnotationComposer,
    $$LocalPicCoversTableCreateCompanionBuilder,
    $$LocalPicCoversTableUpdateCompanionBuilder,
    (
      LocalPicCover,
      BaseReferences<_$AppDatabase, $LocalPicCoversTable, LocalPicCover>
    ),
    LocalPicCover,
    PrefetchHooks Function()>;
typedef $$LocalDownloadsTableCreateCompanionBuilder = LocalDownloadsCompanion
    Function({
  required String songId,
  required String source,
  required String name,
  required String artist,
  Value<String> album,
  Value<String?> picId,
  Value<String?> lyricId,
  Value<String?> coverUrl,
  required String folderPath,
  required String audioPath,
  Value<String?> coverPath,
  Value<String?> lyricsPath,
  Value<DateTime> downloadedAt,
  Value<int> rowid,
});
typedef $$LocalDownloadsTableUpdateCompanionBuilder = LocalDownloadsCompanion
    Function({
  Value<String> songId,
  Value<String> source,
  Value<String> name,
  Value<String> artist,
  Value<String> album,
  Value<String?> picId,
  Value<String?> lyricId,
  Value<String?> coverUrl,
  Value<String> folderPath,
  Value<String> audioPath,
  Value<String?> coverPath,
  Value<String?> lyricsPath,
  Value<DateTime> downloadedAt,
  Value<int> rowid,
});

class $$LocalDownloadsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDownloadsTable> {
  $$LocalDownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get songId => $composableBuilder(
      column: $table.songId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get picId => $composableBuilder(
      column: $table.picId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lyricId => $composableBuilder(
      column: $table.lyricId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderPath => $composableBuilder(
      column: $table.folderPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioPath => $composableBuilder(
      column: $table.audioPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverPath => $composableBuilder(
      column: $table.coverPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lyricsPath => $composableBuilder(
      column: $table.lyricsPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalDownloadsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDownloadsTable> {
  $$LocalDownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get songId => $composableBuilder(
      column: $table.songId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get picId => $composableBuilder(
      column: $table.picId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lyricId => $composableBuilder(
      column: $table.lyricId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderPath => $composableBuilder(
      column: $table.folderPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioPath => $composableBuilder(
      column: $table.audioPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverPath => $composableBuilder(
      column: $table.coverPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lyricsPath => $composableBuilder(
      column: $table.lyricsPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$LocalDownloadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDownloadsTable> {
  $$LocalDownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get picId =>
      $composableBuilder(column: $table.picId, builder: (column) => column);

  GeneratedColumn<String> get lyricId =>
      $composableBuilder(column: $table.lyricId, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get folderPath => $composableBuilder(
      column: $table.folderPath, builder: (column) => column);

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<String> get lyricsPath => $composableBuilder(
      column: $table.lyricsPath, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => column);
}

class $$LocalDownloadsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalDownloadsTable,
    LocalDownload,
    $$LocalDownloadsTableFilterComposer,
    $$LocalDownloadsTableOrderingComposer,
    $$LocalDownloadsTableAnnotationComposer,
    $$LocalDownloadsTableCreateCompanionBuilder,
    $$LocalDownloadsTableUpdateCompanionBuilder,
    (
      LocalDownload,
      BaseReferences<_$AppDatabase, $LocalDownloadsTable, LocalDownload>
    ),
    LocalDownload,
    PrefetchHooks Function()> {
  $$LocalDownloadsTableTableManager(
      _$AppDatabase db, $LocalDownloadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> songId = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> artist = const Value.absent(),
            Value<String> album = const Value.absent(),
            Value<String?> picId = const Value.absent(),
            Value<String?> lyricId = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String> folderPath = const Value.absent(),
            Value<String> audioPath = const Value.absent(),
            Value<String?> coverPath = const Value.absent(),
            Value<String?> lyricsPath = const Value.absent(),
            Value<DateTime> downloadedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalDownloadsCompanion(
            songId: songId,
            source: source,
            name: name,
            artist: artist,
            album: album,
            picId: picId,
            lyricId: lyricId,
            coverUrl: coverUrl,
            folderPath: folderPath,
            audioPath: audioPath,
            coverPath: coverPath,
            lyricsPath: lyricsPath,
            downloadedAt: downloadedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String songId,
            required String source,
            required String name,
            required String artist,
            Value<String> album = const Value.absent(),
            Value<String?> picId = const Value.absent(),
            Value<String?> lyricId = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            required String folderPath,
            required String audioPath,
            Value<String?> coverPath = const Value.absent(),
            Value<String?> lyricsPath = const Value.absent(),
            Value<DateTime> downloadedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalDownloadsCompanion.insert(
            songId: songId,
            source: source,
            name: name,
            artist: artist,
            album: album,
            picId: picId,
            lyricId: lyricId,
            coverUrl: coverUrl,
            folderPath: folderPath,
            audioPath: audioPath,
            coverPath: coverPath,
            lyricsPath: lyricsPath,
            downloadedAt: downloadedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalDownloadsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalDownloadsTable,
    LocalDownload,
    $$LocalDownloadsTableFilterComposer,
    $$LocalDownloadsTableOrderingComposer,
    $$LocalDownloadsTableAnnotationComposer,
    $$LocalDownloadsTableCreateCompanionBuilder,
    $$LocalDownloadsTableUpdateCompanionBuilder,
    (
      LocalDownload,
      BaseReferences<_$AppDatabase, $LocalDownloadsTable, LocalDownload>
    ),
    LocalDownload,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalFavoritesTableTableManager get localFavorites =>
      $$LocalFavoritesTableTableManager(_db, _db.localFavorites);
  $$LocalPlaylistsTableTableManager get localPlaylists =>
      $$LocalPlaylistsTableTableManager(_db, _db.localPlaylists);
  $$LocalPlaylistSongsTableTableManager get localPlaylistSongs =>
      $$LocalPlaylistSongsTableTableManager(_db, _db.localPlaylistSongs);
  $$LocalPlayRecordsTableTableManager get localPlayRecords =>
      $$LocalPlayRecordsTableTableManager(_db, _db.localPlayRecords);
  $$LocalSearchHistoryTableTableManager get localSearchHistory =>
      $$LocalSearchHistoryTableTableManager(_db, _db.localSearchHistory);
  $$LocalPlaySessionsTableTableManager get localPlaySessions =>
      $$LocalPlaySessionsTableTableManager(_db, _db.localPlaySessions);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
  $$LocalSongMetaTableTableManager get localSongMeta =>
      $$LocalSongMetaTableTableManager(_db, _db.localSongMeta);
  $$LocalPlaylistFollowsTableTableManager get localPlaylistFollows =>
      $$LocalPlaylistFollowsTableTableManager(_db, _db.localPlaylistFollows);
  $$LocalRecommendPlaylistsTableTableManager get localRecommendPlaylists =>
      $$LocalRecommendPlaylistsTableTableManager(
          _db, _db.localRecommendPlaylists);
  $$LocalRecommendPlaylistSongsTableTableManager
      get localRecommendPlaylistSongs =>
          $$LocalRecommendPlaylistSongsTableTableManager(
              _db, _db.localRecommendPlaylistSongs);
  $$LocalPicCoversTableTableManager get localPicCovers =>
      $$LocalPicCoversTableTableManager(_db, _db.localPicCovers);
  $$LocalDownloadsTableTableManager get localDownloads =>
      $$LocalDownloadsTableTableManager(_db, _db.localDownloads);
}
