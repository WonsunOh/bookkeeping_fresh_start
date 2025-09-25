// lib/features/transaction/viewmodels/transaction_entry_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums.dart';
import '../../../data/models/account.dart';
import '../../../data/models/transaction.dart';

@immutable
class TransactionEntryState {
  final DateTime date;
  final double amount;
  final String description;
  final EntryScreenType entryType;
  final AccountType? fromAccountType;
  final AccountType? toAccountType;
  final String? fromAccountId;
  final String? toAccountId;

  const TransactionEntryState({
    required this.date,
    required this.amount,
    required this.description,
    required this.entryType,
    this.fromAccountType,
    this.toAccountType,
    this.fromAccountId,
    this.toAccountId,
  });

  TransactionEntryState copyWith({
    DateTime? date,
    double? amount,
    String? description,
    EntryScreenType? entryType,
    AccountType? fromAccountType,
    AccountType? toAccountType,
    String? fromAccountId,
    String? toAccountId,
  }) {
    final bool entryTypeChanged = entryType != null && entryType != this.entryType;
    return TransactionEntryState(
      date: date ?? this.date,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      entryType: entryType ?? this.entryType,
      fromAccountType: entryTypeChanged ? null : (fromAccountType ?? this.fromAccountType),
      toAccountType: entryTypeChanged ? null : (toAccountType ?? this.toAccountType),
      fromAccountId: entryTypeChanged ? null : (fromAccountId ?? this.fromAccountId),
      toAccountId: entryTypeChanged ? null : (toAccountId ?? this.toAccountId),
    );
  }
}

class TransactionEntryViewModel extends Notifier<TransactionEntryState> {
  @override
  TransactionEntryState build() {
    return TransactionEntryState(
      date: DateTime.now(),
      amount: 0.0,
      description: '',
      entryType: EntryScreenType.expense,
      fromAccountType: AccountType.asset,
      toAccountType: AccountType.expense,
    );
  }

  void setDate(DateTime newDate) => state = state.copyWith(date: newDate);
  void setAmount(double newAmount) => state = state.copyWith(amount: newAmount);
  void setDescription(String newDescription) => state = state.copyWith(description: newDescription);

  void setEntryType(EntryScreenType newType) {
    if (state.entryType == newType) return;
    
    AccountType? newFromType;
    AccountType? newToType;

    switch (newType) {
      case EntryScreenType.income:
        newFromType = AccountType.revenue;
        newToType = AccountType.asset;
        break;
      case EntryScreenType.expense:
        newFromType = AccountType.asset;
        newToType = AccountType.expense;
        break;
      case EntryScreenType.transfer:
        newFromType = AccountType.asset;
        newToType = AccountType.asset;
        break;
    }

    state = state.copyWith(
      entryType: newType,
      fromAccountType: newFromType,
      toAccountType: newToType,
    );
  }

  void setFromAccountType(AccountType newType) {
    state = state.copyWith(fromAccountType: newType);
  }

  void setToAccountType(AccountType newType) {
    state = state.copyWith(toAccountType: newType);
  }

  void setFromAccountId(String newId) {
    state = state.copyWith(fromAccountId: newId);
  }

  void setToAccountId(String newId) {
    state = state.copyWith(toAccountId: newId);
  }

  // ✅ 누락된 메서드들 추가
  void setFromAccount(Account account) {
    state = state.copyWith(
      fromAccountId: account.id,
      fromAccountType: account.type,
    );
  }

  void setToAccount(Account account) {
    state = state.copyWith(
      toAccountId: account.id,
      toAccountType: account.type,
    );
  }

  // ✅ reset 메서드 추가
  void reset() {
    state = TransactionEntryState(
      date: DateTime.now(),
      amount: 0.0,
      description: '',
      entryType: EntryScreenType.expense,
      fromAccountType: AccountType.asset,
      toAccountType: AccountType.expense,
    );
  }

  // 수정 모드에서 기존 거래 데이터로 초기화
  void initializeForEdit(Transaction transaction, List<Account> allAccounts) {
    if (transaction.entries.isEmpty) return;

    try {
      final creditEntry = transaction.entries.firstWhere((e) => e.type == EntryType.credit);
      final debitEntry = transaction.entries.firstWhere((e) => e.type == EntryType.debit);

      final fromAccount = allAccounts.firstWhere((a) => a.id == creditEntry.accountId);
      final toAccount = allAccounts.firstWhere((a) => a.id == debitEntry.accountId);

      // 거래 유형 판단
      EntryScreenType entryType;
      if (fromAccount.type == AccountType.asset && toAccount.type == AccountType.expense) {
        entryType = EntryScreenType.expense;
      } else if (fromAccount.type == AccountType.revenue && toAccount.type == AccountType.asset) {
        entryType = EntryScreenType.income;
      } else if (fromAccount.type == AccountType.asset && toAccount.type == AccountType.asset) {
        entryType = EntryScreenType.transfer;
      } else {
        // 기본값
        entryType = EntryScreenType.expense;
      }

      state = TransactionEntryState(
        date: transaction.date,
        amount: debitEntry.amount,
        description: transaction.description,
        entryType: entryType,
        fromAccountType: fromAccount.type,
        toAccountType: toAccount.type,
        fromAccountId: fromAccount.id,
        toAccountId: toAccount.id,
      );
    } catch (e) {
      // 에러 발생 시 기본값으로 초기화
      debugPrint('거래 초기화 중 오류: $e');
      state = TransactionEntryState(
        date: transaction.date,
        amount: 0.0,
        description: transaction.description,
        entryType: EntryScreenType.expense,
        fromAccountType: AccountType.asset,
        toAccountType: AccountType.expense,
      );
    }
  }
}
// Provider 정의
final transactionEntryProvider = NotifierProvider.autoDispose<TransactionEntryViewModel, TransactionEntryState>(() {
  return TransactionEntryViewModel();
});