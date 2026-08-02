// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_history_dao.dart';

// ignore_for_file: type=lint
mixin _$SearchHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalSearchHistoryTable get localSearchHistory =>
      attachedDatabase.localSearchHistory;
  SearchHistoryDaoManager get managers => SearchHistoryDaoManager(this);
}

class SearchHistoryDaoManager {
  final _$SearchHistoryDaoMixin _db;
  SearchHistoryDaoManager(this._db);
  $$LocalSearchHistoryTableTableManager get localSearchHistory =>
      $$LocalSearchHistoryTableTableManager(
          _db.attachedDatabase, _db.localSearchHistory);
}
