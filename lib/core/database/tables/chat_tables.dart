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

@DataClassName("ChatMessageRow")
class ChatMessagesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Local profile key (single-device user / username).
  TextColumn get userId => text().withDefault(const Constant("local"))();

  /// `user` or `assistant`
  TextColumn get role => text()();

  TextColumn get content => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName("ChatMemoryRow")
class ChatMemoriesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get userId => text().withDefault(const Constant("local"))();

  /// Short factual memory suitable for long-term recall.
  TextColumn get content => text()();

  /// Optional tags for retrieval (comma-separated keywords).
  TextColumn get tags => text().withDefault(const Constant(""))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
