// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_dao.dart';

// ignore_for_file: type=lint
mixin _$PlaylistDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalPlaylistsTable get localPlaylists => attachedDatabase.localPlaylists;
  $LocalPlaylistSongsTable get localPlaylistSongs =>
      attachedDatabase.localPlaylistSongs;
  PlaylistDaoManager get managers => PlaylistDaoManager(this);
}

class PlaylistDaoManager {
  final _$PlaylistDaoMixin _db;
  PlaylistDaoManager(this._db);
  $$LocalPlaylistsTableTableManager get localPlaylists =>
      $$LocalPlaylistsTableTableManager(
          _db.attachedDatabase, _db.localPlaylists);
  $$LocalPlaylistSongsTableTableManager get localPlaylistSongs =>
      $$LocalPlaylistSongsTableTableManager(
          _db.attachedDatabase, _db.localPlaylistSongs);
}
