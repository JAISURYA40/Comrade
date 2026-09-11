// ignore_for_file: file_names

import 'package:drift/drift.dart';
import 'package:comrade/core/utils/db_utils.dart';

Future<void> from9To10(Migrator m, TableInfo chatMessagesTable,
        TableInfo chatMemoriesTable) async =>
    await runSafe(
      "Migration(9 to 10)",
      () async {
        await m.createTable(chatMessagesTable);
        await m.createTable(chatMemoriesTable);
      },
    );
