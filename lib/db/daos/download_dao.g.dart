// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_dao.dart';

// ignore_for_file: type=lint
mixin _$DownloadDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalDownloadsTable get localDownloads => attachedDatabase.localDownloads;
  DownloadDaoManager get managers => DownloadDaoManager(this);
}

class DownloadDaoManager {
  final _$DownloadDaoMixin _db;
  DownloadDaoManager(this._db);
  $$LocalDownloadsTableTableManager get localDownloads =>
      $$LocalDownloadsTableTableManager(
          _db.attachedDatabase, _db.localDownloads);
}
