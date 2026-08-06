// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pic_cover_dao.dart';

// ignore_for_file: type=lint
mixin _$PicCoverDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalPicCoversTable get localPicCovers => attachedDatabase.localPicCovers;
  PicCoverDaoManager get managers => PicCoverDaoManager(this);
}

class PicCoverDaoManager {
  final _$PicCoverDaoMixin _db;
  PicCoverDaoManager(this._db);
  $$LocalPicCoversTableTableManager get localPicCovers =>
      $$LocalPicCoversTableTableManager(
          _db.attachedDatabase, _db.localPicCovers);
}
