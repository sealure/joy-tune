// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$LyricsCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalLyricsCacheTable get localLyricsCache =>
      attachedDatabase.localLyricsCache;
  LyricsCacheDaoManager get managers => LyricsCacheDaoManager(this);
}

class LyricsCacheDaoManager {
  final _$LyricsCacheDaoMixin _db;
  LyricsCacheDaoManager(this._db);
  $$LocalLyricsCacheTableTableManager get localLyricsCache =>
      $$LocalLyricsCacheTableTableManager(
          _db.attachedDatabase, _db.localLyricsCache);
}
