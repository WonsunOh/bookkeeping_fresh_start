// lib/core/utils/data_consistency_checker.dart
import '../enums.dart';
import '../../data/models/account.dart';
import '../../data/models/transaction.dart';
import 'transaction_utils.dart';

class DataInconsistencyReport {
  final Transaction transaction;
  final EntryScreenType expectedType;
  final String fromAccountName;
  final String toAccountName;
  final AccountType fromAccountType;
  final AccountType toAccountType;
  final String reason;

  DataInconsistencyReport({
    required this.transaction,
    required this.expectedType,
    required this.fromAccountName,
    required this.toAccountName,
    required this.fromAccountType,
    required this.toAccountType,
    required this.reason,
  });
}

class DataConsistencyChecker {
  /// 모든 거래 데이터의 일관성을 체크합니다
  static List<DataInconsistencyReport> checkAllTransactions(
    List<Transaction> transactions,
    List<Account> accounts,
  ) {
    final List<DataInconsistencyReport> inconsistencies = [];

    for (final transaction in transactions) {
      try {
        final report = checkTransaction(transaction, accounts);
        if (report != null) {
          inconsistencies.add(report);
        }
      } catch (e) {
        // print('거래 ${transaction.id} 체크 중 오류: $e');
      }
    }

    return inconsistencies;
  }

  /// 개별 거래의 일관성을 체크합니다
  static DataInconsistencyReport? checkTransaction(
    Transaction transaction,
    List<Account> accounts,
  ) {
    try {
      final debitEntry = transaction.entries.firstWhere((e) => e.type == EntryType.debit);
      final creditEntry = transaction.entries.firstWhere((e) => e.type == EntryType.credit);

      final fromAcc = accounts.firstWhere((a) => a.id == creditEntry.accountId);
      final toAcc = accounts.firstWhere((a) => a.id == debitEntry.accountId);

      // TransactionUtils로 현재 로직에 따른 예상 타입 계산
      final expectedType = TransactionUtils.determineTransactionType(transaction, accounts);

      // 의심스러운 패턴들을 체크
      String? suspiciousReason;

      // 1. 자산 -> 부채인데 이체라고 생각할 수 있는 케이스
      if (fromAcc.type == AccountType.asset && toAcc.type == AccountType.liability) {
        if (transaction.description.contains('이체') || transaction.description.contains('transfer')) {
          suspiciousReason = '이체라고 명시되어 있지만 실제로는 자산->부채(지출) 패턴';
        }
      }

      // 2. 자산 -> 자산인데 설명이 지출 관련인 케이스
      if (fromAcc.type == AccountType.asset && toAcc.type == AccountType.asset) {
        if (transaction.description.contains('결제') || 
            transaction.description.contains('지출') ||
            transaction.description.contains('구매')) {
          suspiciousReason = '지출 관련 설명이지만 자산->자산(이체) 패턴';
        }
      }

      // 3. 일반적으로 의심스러운 패턴들
      if (fromAcc.type == AccountType.expense && toAcc.type == AccountType.asset) {
        suspiciousReason = '비용->자산 패턴 (일반적이지 않음)';
      }

      if (suspiciousReason != null) {
        return DataInconsistencyReport(
          transaction: transaction,
          expectedType: expectedType,
          fromAccountName: fromAcc.name,
          toAccountName: toAcc.name,
          fromAccountType: fromAcc.type,
          toAccountType: toAcc.type,
          reason: suspiciousReason,
        );
      }

      return null; // 문제없음
    } catch (e) {
      return DataInconsistencyReport(
        transaction: transaction,
        expectedType: EntryScreenType.expense,
        fromAccountName: '오류',
        toAccountName: '오류',
        fromAccountType: AccountType.asset,
        toAccountType: AccountType.expense,
        reason: '거래 분석 중 오류 발생: $e',
      );
    }
  }

  /// 거래 패턴별 통계를 생성합니다
  static Map<String, int> generatePatternStats(
    List<Transaction> transactions,
    List<Account> accounts,
  ) {
    final Map<String, int> stats = {};

    for (final transaction in transactions) {
      try {
        final debitEntry = transaction.entries.firstWhere((e) => e.type == EntryType.debit);
        final creditEntry = transaction.entries.firstWhere((e) => e.type == EntryType.credit);

        final fromAcc = accounts.firstWhere((a) => a.id == creditEntry.accountId);
        final toAcc = accounts.firstWhere((a) => a.id == debitEntry.accountId);

        final pattern = '${fromAcc.type.name} → ${toAcc.type.name}';
        stats[pattern] = (stats[pattern] ?? 0) + 1;
      } catch (e) {
        stats['오류'] = (stats['오류'] ?? 0) + 1;
      }
    }

    return stats;
  }

  /// 거래 유형별 통계를 생성합니다
  static Map<EntryScreenType, int> generateTypeStats(
    List<Transaction> transactions,
    List<Account> accounts,
  ) {
    final Map<EntryScreenType, int> stats = {};

    for (final transaction in transactions) {
      try {
        final type = TransactionUtils.determineTransactionType(transaction, accounts);
        stats[type] = (stats[type] ?? 0) + 1;
      } catch (e) {
        // 오류 발생한 거래는 스킵
      }
    }

    return stats;
  }
}