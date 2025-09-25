// lib/core/utils/data_migration_tool.dart
import '../enums.dart';
import '../../data/models/account.dart';
import '../../data/models/transaction.dart';
import '../../data/models/journal_entry.dart';

class DataMigrationTool {
  /// 잘못된 분개를 수정하는 함수
  /// 예: "현금 결제"인데 현금->현금으로 되어있는 경우를 현금->비용으로 수정
  static Transaction? fixIncorrectTransaction(
    Transaction transaction,
    List<Account> accounts,
    {String? newDebitAccountId, String? newCreditAccountId}
  ) {
    try {
      final debitEntry = transaction.entries.firstWhere((e) => e.type == EntryType.debit);
      final creditEntry = transaction.entries.firstWhere((e) => e.type == EntryType.credit);

      // 새로운 분개 생성
      final newEntries = [
        JournalEntry(
          accountId: newDebitAccountId ?? debitEntry.accountId,
          type: EntryType.debit,
          amount: debitEntry.amount,
        ),
        JournalEntry(
          accountId: newCreditAccountId ?? creditEntry.accountId,
          type: EntryType.credit,
          amount: creditEntry.amount,
        ),
      ];

      return Transaction(
        id: transaction.id,
        date: transaction.date,
        description: transaction.description,
        entries: newEntries,
      );
    } catch (e) {
      // print('거래 수정 실패: $e');
      return null;
    }
  }

  /// 계정 유형 기반 자동 수정 제안
  static Map<String, String> suggestAccountCorrection(
    Transaction transaction,
    List<Account> accounts,
  ) {
    final Map<String, String> suggestions = {};

    try {
      final debitEntry = transaction.entries.firstWhere((e) => e.type == EntryType.debit);
      final creditEntry = transaction.entries.firstWhere((e) => e.type == EntryType.credit);

      final fromAcc = accounts.firstWhere((a) => a.id == creditEntry.accountId);
      final toAcc = accounts.firstWhere((a) => a.id == debitEntry.accountId);

      // 의심스러운 패턴별 제안
      if (fromAcc.type == AccountType.asset && toAcc.type == AccountType.asset) {
        // 자산->자산이지만 설명이 지출 관련인 경우
        if (transaction.description.contains('결제') || 
            transaction.description.contains('구매') ||
            transaction.description.contains('지출')) {
          
          // 비용 계정 찾기
          final expenseAccount = accounts.firstWhere(
            (a) => a.type == AccountType.expense,
            orElse: () => accounts.firstWhere((a) => a.name.contains('비용')),
          );
          
          suggestions['debit'] = expenseAccount.id;
          suggestions['reason'] = '지출 관련 설명이므로 비용 계정으로 변경 제안';
        }
      }

      if (fromAcc.type == AccountType.asset && toAcc.type == AccountType.liability) {
        // 자산->부채인 경우는 대부분 정상이지만, 이체라고 명시된 경우만 체크
        if (transaction.description.contains('이체')) {
          final assetAccounts = accounts.where((a) => 
            a.type == AccountType.asset && a.id != fromAcc.id
          ).toList();
          
          if (assetAccounts.isNotEmpty) {
            suggestions['debit'] = assetAccounts.first.id;
            suggestions['reason'] = '이체라고 명시되어 있으므로 자산 계정으로 변경 제안';
          }
        }
      }

    } catch (e) {
      suggestions['error'] = '분석 실패: $e';
    }

    return suggestions;
  }

  /// 일괄 데이터 정리를 위한 배치 작업
  static List<Transaction> batchFixTransactions(
    List<Transaction> transactions,
    List<Account> accounts,
    Map<String, Map<String, String>> fixInstructions,
  ) {
    final List<Transaction> fixedTransactions = [];

    for (final transaction in transactions) {
      final instruction = fixInstructions[transaction.id];
      if (instruction != null) {
        final fixed = fixIncorrectTransaction(
          transaction,
          accounts,
          newDebitAccountId: instruction['debit'],
          newCreditAccountId: instruction['credit'],
        );
        if (fixed != null) {
          fixedTransactions.add(fixed);
        }
      }
    }

    return fixedTransactions;
  }

  /// CSV 형태로 문제있는 거래 목록 생성
  static String generateInconsistencyCSV(
    List<Transaction> transactions,
    List<Account> accounts,
  ) {
    final StringBuffer csv = StringBuffer();
    csv.writeln('거래ID,날짜,설명,금액,출금계정,입금계정,출금유형,입금유형,예상유형,문제점');

    for (final transaction in transactions) {
      try {
        final debitEntry = transaction.entries.firstWhere((e) => e.type == EntryType.debit);
        final creditEntry = transaction.entries.firstWhere((e) => e.type == EntryType.credit);

        final fromAcc = accounts.firstWhere((a) => a.id == creditEntry.accountId);
        final toAcc = accounts.firstWhere((a) => a.id == debitEntry.accountId);

        String issue = '';
        if (fromAcc.type == AccountType.asset && toAcc.type == AccountType.asset &&
            (transaction.description.contains('결제') || transaction.description.contains('구매'))) {
          issue = '지출인듯한데_이체패턴';
        } else if (fromAcc.type == AccountType.asset && toAcc.type == AccountType.liability &&
                   transaction.description.contains('이체')) {
          issue = '이체라고_하는데_지출패턴';
        }

        if (issue.isNotEmpty) {
          csv.writeln([
            transaction.id,
            transaction.date.toIso8601String().split('T')[0],
            '"${transaction.description}"',
            debitEntry.amount,
            fromAcc.name,
            toAcc.name,
            fromAcc.type.name,
            toAcc.type.name,
            '판별필요',
            issue,
          ].join(','));
        }
      } catch (e) {
        csv.writeln('${transaction.id},오류,오류,0,오류,오류,오류,오류,오류,분석실패');
      }
    }

    return csv.toString();
  }
}