// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_dao.dart';

// ignore_for_file: type=lint
mixin _$SessionDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalPlaySessionsTable get localPlaySessions =>
      attachedDatabase.localPlaySessions;
  SessionDaoManager get managers => SessionDaoManager(this);
}

class SessionDaoManager {
  final _$SessionDaoMixin _db;
  SessionDaoManager(this._db);
  $$LocalPlaySessionsTableTableManager get localPlaySessions =>
      $$LocalPlaySessionsTableTableManager(
          _db.attachedDatabase, _db.localPlaySessions);
}
