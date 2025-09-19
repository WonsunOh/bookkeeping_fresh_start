// lib/data/local/connection/unsupported.dart
import 'package:drift/drift.dart';

QueryExecutor openConnection() {
  throw UnsupportedError('This platform is not supported for database');
}