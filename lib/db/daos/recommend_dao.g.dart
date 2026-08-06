// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommend_dao.dart';

// ignore_for_file: type=lint
mixin _$RecommendDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalRecommendPlaylistsTable get localRecommendPlaylists =>
      attachedDatabase.localRecommendPlaylists;
  $LocalRecommendPlaylistSongsTable get localRecommendPlaylistSongs =>
      attachedDatabase.localRecommendPlaylistSongs;
  $LocalSettingsTable get localSettings => attachedDatabase.localSettings;
  RecommendDaoManager get managers => RecommendDaoManager(this);
}

class RecommendDaoManager {
  final _$RecommendDaoMixin _db;
  RecommendDaoManager(this._db);
  $$LocalRecommendPlaylistsTableTableManager get localRecommendPlaylists =>
      $$LocalRecommendPlaylistsTableTableManager(
          _db.attachedDatabase, _db.localRecommendPlaylists);
  $$LocalRecommendPlaylistSongsTableTableManager
      get localRecommendPlaylistSongs =>
          $$LocalRecommendPlaylistSongsTableTableManager(
              _db.attachedDatabase, _db.localRecommendPlaylistSongs);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db.attachedDatabase, _db.localSettings);
}
