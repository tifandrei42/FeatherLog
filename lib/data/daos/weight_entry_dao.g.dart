// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_entry_dao.dart';

// ignore_for_file: type=lint
mixin _$WeightEntryDaoMixin on DatabaseAccessor<AppDatabase> {
  $WeightEntriesTable get weightEntries => attachedDatabase.weightEntries;
  WeightEntryDaoManager get managers => WeightEntryDaoManager(this);
}

class WeightEntryDaoManager {
  final _$WeightEntryDaoMixin _db;
  WeightEntryDaoManager(this._db);
  $$WeightEntriesTableTableManager get weightEntries =>
      $$WeightEntriesTableTableManager(_db.attachedDatabase, _db.weightEntries);
}
