// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_follow_dao.dart';

// ignore_for_file: type=lint
mixin _$PlaylistFollowDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalPlaylistFollowsTable get localPlaylistFollows =>
      attachedDatabase.localPlaylistFollows;
  PlaylistFollowDaoManager get managers => PlaylistFollowDaoManager(this);
}

class PlaylistFollowDaoManager {
  final _$PlaylistFollowDaoMixin _db;
  PlaylistFollowDaoManager(this._db);
  $$LocalPlaylistFollowsTableTableManager get localPlaylistFollows =>
      $$LocalPlaylistFollowsTableTableManager(
          _db.attachedDatabase, _db.localPlaylistFollows);
}
