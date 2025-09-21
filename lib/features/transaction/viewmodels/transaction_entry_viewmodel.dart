// lib/features/transaction/viewmodels/transaction_entry_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

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
  // --- ▼ [수정] Account 객체 대신 String ID를 저장합니다 ---
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

class TransactionEntryViewModel extends StateNotifier<TransactionEntryState> {
  TransactionEntryViewModel()
      : super(
          TransactionEntryState(
            date: DateTime.now(),
            amount: 0.0,
            description: '',
            entryType: EntryScreenType.expense,
            fromAccountType: AccountType.asset,
            toAccountType: AccountType.expense,
          ),
        );

  void setDate(DateTime newDate) => state = state.copyWith(date: newDate);
  void setAmount(double newAmount) => state = state.copyWith(amount: newAmount);
  void setDescription(String newDescription) => state = state.copyWith(description: newDescription);

  void setEntryType(EntryScreenType newType) {
    if (state.entryType == newType) return;
    AccountType? newFromType;
    AccountType? newToType;
    switch (newType) {
      case EntryScreenType.income: newToType = AccountType.asset; break;
      case EntryScreenType.expense: newFromType = AccountType.asset; newToType = AccountType.expense; break;
      case EntryScreenType.transfer: newFromType = AccountType.asset; newToType = AccountType.asset; break;
    }
    state = state.copyWith(
      entryType: newType,
      fromAccountType: newFromType,
      toAccountType: newToType,
    );
  }

  void setFromAccountType(AccountType type) {
    state = state.copyWith(fromAccountType: type, fromAccountId: null);
  }

  void setToAccountType(AccountType type) {
    state = state.copyWith(toAccountType: type, toAccountId: null);
  }

  void setFromAccount(Account? account) {
    state = state.copyWith(fromAccountId: account?.id, fromAccountType: account?.type);
  }

  void setToAccount(Account? account) {
    state = state.copyWith(toAccountId: account?.id, toAccountType: account?.type);
  }

  void initializeForEdit(Transaction transaction, List<Account> allAccounts) {
    final creditEntry = transaction.entries.firstWhere((e) => e.type == EntryType.credit);
    final debitEntry = transaction.entries.firstWhere((e) => e.type == EntryType.debit);
    final fromAcc = allAccounts.firstWhere((a) => a.id == creditEntry.accountId);
    final toAcc = allAccounts.firstWhere((a) => a.id == debitEntry.accountId);
    EntryScreenType type;
    if (fromAcc.type == AccountType.asset && toAcc.type == AccountType.asset) {
      type = EntryScreenType.transfer;
    } else if ((fromAcc.type == AccountType.asset || fromAcc.type == AccountType.liability) && (toAcc.type == AccountType.expense || toAcc.type == AccountType.equity)) {
      type = EntryScreenType.expense;
    } else {
      type = EntryScreenType.income;
    }
    
    state = TransactionEntryState(
      date: transaction.date,
      amount: debitEntry.amount,
      description: transaction.description,
      fromAccountId: fromAcc.id,
      toAccountId: toAcc.id,
      fromAccountType: fromAcc.type,
      toAccountType: toAcc.type,
      entryType: type,
    );
  }
}

final transactionEntryProvider = StateNotifierProvider.autoDispose<TransactionEntryViewModel, TransactionEntryState>(
  (ref) => TransactionEntryViewModel(),
);