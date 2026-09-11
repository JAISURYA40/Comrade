/*
 *
 *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:drift/drift.dart';
import 'package:comrade/core/database/app_database.dart';
import 'package:comrade/core/database/tables/chat_tables.dart';

part 'chat_records_dao.g.dart';

@DriftAccessor(tables: [ChatMessagesTable, ChatMemoriesTable])
class ChatRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$ChatRecordsDaoMixin {
  ChatRecordsDao(super.db);

  Future<List<ChatMessageRow>> fetchRecentMessages({
    required String userId,
    int limit = 40,
  }) {
    return (select(chatMessagesTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .get()
        .then((rows) => rows.reversed.toList());
  }

  Future<void> insertMessage({
    required String userId,
    required String role,
    required String content,
    DateTime? createdAt,
  }) {
    return into(chatMessagesTable).insert(
      ChatMessagesTableCompanion.insert(
        userId: Value(userId),
        role: role,
        content: content,
        createdAt: Value(createdAt ?? DateTime.now()),
      ),
    );
  }

  Future<List<ChatMemoryRow>> fetchAllMemories({required String userId}) {
    return (select(chatMemoriesTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<void> upsertMemory({
    required String userId,
    required String content,
    String tags = '',
  }) async {
    final existing = await (select(chatMemoriesTable)
          ..where((t) => t.userId.equals(userId) & t.content.equals(content)))
        .getSingleOrNull();
    if (existing != null) {
      await (update(chatMemoriesTable)..where((t) => t.id.equals(existing.id)))
          .write(ChatMemoriesTableCompanion(
        tags: Value(tags.isEmpty ? existing.tags : tags),
        updatedAt: Value(DateTime.now()),
      ));
      return;
    }
    await into(chatMemoriesTable).insert(
      ChatMemoriesTableCompanion.insert(
        userId: Value(userId),
        content: content,
        tags: Value(tags),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> trimMessages({
    required String userId,
    int keep = 200,
  }) async {
    final rows = await (select(chatMessagesTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    if (rows.length <= keep) return;
    final dropIds = rows.skip(keep).map((e) => e.id).toList();
    await (delete(chatMessagesTable)..where((t) => t.id.isIn(dropIds))).go();
  }
}
