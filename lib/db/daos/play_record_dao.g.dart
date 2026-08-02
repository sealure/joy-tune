// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_record_dao.dart';

// ignore_for_file: type=lint
mixin _$PlayRecordDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalPlayRecordsTable get localPlayRecords =>
      attachedDatabase.localPlayRecords;
  PlayRecordDaoManager get managers => PlayRecordDaoManager(this);
}

class PlayRecordDaoManager {
  final _$PlayRecordDaoMixin _db;
  PlayRecordDaoManager(this._db);
  $$LocalPlayRecordsTableTableManager get localPlayRecords =>
      $$LocalPlayRecordsTableTableManager(
          _db.attachedDatabase, _db.localPlayRecords);
}
