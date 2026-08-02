// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_dao.dart';

// ignore_for_file: type=lint
mixin _$FavoriteDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalFavoritesTable get localFavorites => attachedDatabase.localFavorites;
  FavoriteDaoManager get managers => FavoriteDaoManager(this);
}

class FavoriteDaoManager {
  final _$FavoriteDaoMixin _db;
  FavoriteDaoManager(this._db);
  $$LocalFavoritesTableTableManager get localFavorites =>
      $$LocalFavoritesTableTableManager(
          _db.attachedDatabase, _db.localFavorites);
}
