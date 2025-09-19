// lib/data/local/database_helper.dart

// 1. 이 import 구문이 누락되어 모든 문제가 발생했습니다.
import 'package:drift/drift.dart';

import '../../core/enums.dart';
import 'connection/shared.dart' as connection;

part 'database_helper.g.dart';

// --- 테이블 정의 ---
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text().map(const EnumNameConverter(AccountType.values))();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class JournalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get type => text().map(const EnumNameConverter(EntryType.values))();
  RealColumn get amount => real()();
}

// --- 데이터베이스 클래스 ---
@DriftDatabase(tables: [Accounts, Transactions, JournalEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(connection.openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // 기본 계정과목 추가
          await batch((batch) {
            batch.insertAll(accounts, [
              AccountsCompanion.insert(id: 'asset_cash', name: '현금', type: AccountType.asset),
              AccountsCompanion.insert(id: 'asset_bank', name: '보통예금', type: AccountType.asset),
              AccountsCompanion.insert(id: 'expense_food', name: '식비', type: AccountType.expense),
              AccountsCompanion.insert(id: 'expense_transport', name: '교통비', type: AccountType.expense),
              AccountsCompanion.insert(id: 'revenue_salary', name: '급여소득', type: AccountType.revenue),
            ]);
          });
        },
        onUpgrade: (m, from, to) async {
          if (from == 1) {
            await m.createTable(accounts);
          }
        },
      );
}