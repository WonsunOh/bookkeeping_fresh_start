// lib/features/transaction/viewmodels/transaction_entry_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/enums.dart';
import '../../../data/models/account.dart';
import '../../../data/models/transaction.dart';

// 거래 기록 화면의 상태를 나타내는 클래스
class TransactionEntryState {
  final DateTime date;
  final Account? fromAccount; // 출금 계좌 (자산)
  final Account? toAccount; // 입금 계좌 또는 비용/수익/자산 계정
  final double amount;
  final String description;
  final EntryScreenType entryType; // 거래 유형 상태 추가

  TransactionEntryState({
    required this.date,
    this.fromAccount,
    this.toAccount,
    this.amount = 0.0,
    this.description = '',
    this.entryType = EntryScreenType.expense, // 기본값은 '지출'
  });

  TransactionEntryState copyWith({
    DateTime? date,
    Account? fromAccount,
    // toAccount를 null로 초기화할 수 있도록 변경
    Account? toAccount,
    double? amount,
    String? description,
    EntryScreenType? entryType,
    bool resetToAccount = false,
  }) {
    return TransactionEntryState(
      date: date ?? this.date,
      fromAccount: fromAccount ?? this.fromAccount,
      toAccount: resetToAccount ? null : toAccount ?? this.toAccount,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      entryType: entryType ?? this.entryType,
    );
  }
}

// TransactionEntryState를 관리하는 Notifier
class TransactionEntryViewModel extends StateNotifier<TransactionEntryState> {
  final Ref ref;
  TransactionEntryViewModel(this.ref) : super(TransactionEntryState(date: DateTime.now()));

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void setFromAccount(Account account) {
    state = state.copyWith(fromAccount: account);
  }

  void setToAccount(Account account) {
    state = state.copyWith(toAccount: account);
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  // 거래 유형을 변경하는 메서드 추가
  void setEntryType(EntryScreenType type) {
    // 유형이 변경되면 대상 계정(toAccount) 선택을 초기화하여 오류를 방지합니다.
    state = state.copyWith(entryType: type, resetToAccount: true);
  }

  // 수정 모드를 위해 거래 데이터로 상태를 초기화하는 메서드
  void initializeForEdit(Transaction transaction, List<Account> allAccounts) {
    final debitEntry = transaction.entries.firstWhere((e) => e.type == EntryType.debit);
    final creditEntry = transaction.entries.firstWhere((e) => e.type == EntryType.credit);
    
    // 전달받은 계정 목록에서 필요한 계정을 찾습니다.
    final fromAccount = allAccounts.firstWhere((acc) => acc.id == creditEntry.accountId);
    final toAccount = allAccounts.firstWhere((acc) => acc.id == debitEntry.accountId);
    
    EntryScreenType type;
    if (toAccount.type == AccountType.expense) {
      type = EntryScreenType.expense;
    } else if (toAccount.type == AccountType.revenue) {
      type = EntryScreenType.income;
    } else {
      type = EntryScreenType.transfer;
    }

    state = TransactionEntryState(
      date: transaction.date,
      fromAccount: fromAccount,
      toAccount: toAccount,
      amount: transaction.entries.first.amount,
      description: transaction.description,
      entryType: type,
    );
  }

}

final transactionEntryProvider =
    StateNotifierProvider.autoDispose<TransactionEntryViewModel, TransactionEntryState>(
  (ref) => TransactionEntryViewModel(ref), // ref 전달
);