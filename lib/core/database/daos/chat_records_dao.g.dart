// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_records_dao.dart';

// ignore_for_file: type=lint
mixin _$ChatRecordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ChatMessagesTableTable get chatMessagesTable =>
      attachedDatabase.chatMessagesTable;
  $ChatMemoriesTableTable get chatMemoriesTable =>
      attachedDatabase.chatMemoriesTable;
  ChatRecordsDaoManager get managers => ChatRecordsDaoManager(this);
}

class ChatRecordsDaoManager {
  final _$ChatRecordsDaoMixin _db;
  ChatRecordsDaoManager(this._db);
  $$ChatMessagesTableTableTableManager get chatMessagesTable =>
      $$ChatMessagesTableTableTableManager(
          _db.attachedDatabase, _db.chatMessagesTable);
  $$ChatMemoriesTableTableTableManager get chatMemoriesTable =>
      $$ChatMemoriesTableTableTableManager(
          _db.attachedDatabase, _db.chatMemoriesTable);
}
