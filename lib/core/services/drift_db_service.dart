/*
 *
 *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */


import 'package:drift_flutter/drift_flutter.dart';
import 'package:comrade/core/database/app_database.dart';

/// A service class responsible for interacting with the Drift database.
///
/// This class provides methods for initializing the Drift database,
class DriftDbService {
  /// Private constructor to enforce singleton pattern.
  DriftDbService._();

  /// Singleton instance of the [DriftDbService].
  static final DriftDbService instance = DriftDbService._();

  /// Instance used for database operations.
  late AppDatabase driftDb;

  /// Initializes the Drift database service.
  ///
  /// This method should be called once in the application's main method
  /// to set up the database.
  Future<void> init() async => driftDb = await _createIsolatedDb();

  /// Creates two separate executors for read and write operations
  Future<AppDatabase> _createIsolatedDb() async {
    final db = driftDatabase(
      name: 'Comrade',
      native: const DriftNativeOptions(),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
        onResult: (result) {
          if (result.missingFeatures.isNotEmpty) {
            print('Using fallback web database because of missing features: ${result.missingFeatures}');
          }
        },
      ),
    );

    return AppDatabase(db);
  }
}
