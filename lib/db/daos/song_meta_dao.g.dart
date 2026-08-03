// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_meta_dao.dart';

// ignore_for_file: type=lint
mixin _$SongMetaDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalSongMetaTable get localSongMeta => attachedDatabase.localSongMeta;
  SongMetaDaoManager get managers => SongMetaDaoManager(this);
}

class SongMetaDaoManager {
  final _$SongMetaDaoMixin _db;
  SongMetaDaoManager(this._db);
  $$LocalSongMetaTableTableManager get localSongMeta =>
      $$LocalSongMetaTableTableManager(_db.attachedDatabase, _db.localSongMeta);
}
