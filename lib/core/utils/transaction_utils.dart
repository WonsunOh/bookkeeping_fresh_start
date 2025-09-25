// lib/core/utils/transaction_utils.dart
import '../enums.dart';
import '../../data/models/account.dart';
import '../../data/models/transaction.dart';

class TransactionUtils {
  /// 거래의 유형을 판별하는 공통 함수
  /// Transaction과 Account 목록을 받아서 EntryScreenType을 반환
  static EntryScreenType determineTransactionType(Transaction transaction, List<Account> accounts) {
    final debitEntry = transaction.entries.firstWhere((e) => e.type == EntryType.debit);
    final creditEntry = transaction.entries.firstWhere((e) => e.type == EntryType.credit);

    // 계정을 찾을 때 안전장치 추가
    final fromAcc = accounts.firstWhere(
      (a) => a.id == creditEntry.accountId,
      orElse: () => throw Exception('Credit 계정을 찾을 수 없습니다: ${creditEntry.accountId}'),
    );
    final toAcc = accounts.firstWhere(
      (a) => a.id == debitEntry.accountId,
      orElse: () => throw Exception('Debit 계정을 찾을 수 없습니다: ${debitEntry.accountId}'),
    );

    // 거래 유형 판별 로직
    if (fromAcc.type == AccountType.asset && (toAcc.type == AccountType.asset || toAcc.type == AccountType.liability)) {
      // 자산 → 자산/부채 = 이체
      return EntryScreenType.transfer;

    } else if ((fromAcc.type == AccountType.asset || fromAcc.type == AccountType.liability) && 
               (toAcc.type == AccountType.expense || toAcc.type == AccountType.equity || toAcc.type == AccountType.liability)) {
      // 자산/부채 → 비용/자본/부채 = 지출
      return EntryScreenType.expense;

    } else if ((fromAcc.type == AccountType.revenue || fromAcc.type == AccountType.equity || fromAcc.type == AccountType.liability || fromAcc.type == AccountType.expense) && 
               (toAcc.type == AccountType.asset || toAcc.type == AccountType.liability)) {
      // 수익/자본/부채/비용 → 자산/부채 = 수입
      return EntryScreenType.income;

    } else {
      // 기타 경우는 지출로 처리 (안전한 기본값)
      return EntryScreenType.expense;
    }
  }

  /// 거래 유형의 한글 이름을 반환
  static String getTransactionTypeName(EntryScreenType type) {
    switch (type) {
      case EntryScreenType.expense:
        return '지출';
      case EntryScreenType.income:
        return '수입';
      case EntryScreenType.transfer:
        return '이체';
    }
  }
}