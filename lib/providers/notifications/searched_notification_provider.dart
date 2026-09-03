/*
 *
 *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comrade/core/database/app_database.dart';
import 'package:comrade/core/services/drift_db_service.dart';

final searchedNotificationsProvider =
    FutureProvider.family<List<Notification>, String>(
  (ref, query) async => query.isEmpty
      ? Future.value([])
      : DriftDbService.instance.driftDb.dynamicRecordsDao
          .searchNotificationsWithQuery(query: query),
);
