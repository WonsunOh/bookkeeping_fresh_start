// lib/data/local/connection/web.dart
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

DatabaseConnection openConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(
        databaseName: 'double-entry-db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
      if (result.missingFeatures.isNotEmpty && kDebugMode) {
        if (kDebugMode) {
          print('Using ${result.chosenImplementation} due to unsupported features: ${result.missingFeatures}');
        }
      }
      return result.resolvedExecutor;
    }),
  );
}