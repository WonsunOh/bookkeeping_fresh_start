// lib/features/repeating_transactions/viewmodels/repeating_transaction_entry_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/enums.dart';
import '../../../data/models/account.dart';
import '../../../data/models/repeating_transaction.dart';
import '../../../data/models/transaction.dart';

// 반복 거래 설정 화면의 상태를 나타내는 클래스
@immutable
class RepeatingEntryState {
  final String description;
  final double amount;
  final Account? fromAccount;
  final Account? toAccount;
  final EntryScreenType entryType;
  final Frequency frequency;
  final DateTime nextDueDate;
  final DateTime? endDate;

  const RepeatingEntryState({
    this.description = '',
    this.amount = 0.0,
    this.fromAccount,
    this.toAccount,
    this.entryType = EntryScreenType.expense,
    this.frequency = Frequency.monthly,
    required this.nextDueDate,
    this.endDate,
  });

  RepeatingEntryState copyWith({
    String? description,
    double? amount,
    Account? fromAccount,
    Account? toAccount,
    EntryScreenType? entryType,
    Frequency? frequency,
    DateTime? nextDueDate,
    DateTime? endDate,
    bool resetToAccount = false,
  }) {
    return RepeatingEntryState(
      description: description ?? this.description,
      amount: amount ?? this.amount,
      fromAccount: fromAccount ?? this.fromAccount,
      toAccount: resetToAccount ? null : toAccount ?? this.toAccount,
      entryType: entryType ?? this.entryType,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

// 상태를 관리하는 Notifier
class RepeatingEntryViewModel extends StateNotifier<RepeatingEntryState> {
  RepeatingEntryViewModel() : super(RepeatingEntryState(nextDueDate: DateTime.now()));

  void initializeForEdit(RepeatingTransaction rule, List<Account> allAccounts) {
    state = RepeatingEntryState(
      description: rule.description,
      amount: rule.amount,
      fromAccount: allAccounts.firstWhere((a) => a.id == rule.fromAccountId),
      toAccount: allAccounts.firstWhere((a) => a.id == rule.toAccountId),
      entryType: rule.entryType,
      frequency: rule.frequency,
      nextDueDate: rule.nextDueDate,
      endDate: rule.endDate,
    );
  }

  void setDescription(String value) => state = state.copyWith(description: value);
  void setAmount(double value) => state = state.copyWith(amount: value);
  void setFromAccount(Account value) => state = state.copyWith(fromAccount: value);
  void setToAccount(Account value) => state = state.copyWith(toAccount: value);
  void setEntryType(EntryScreenType value) => state = state.copyWith(entryType: value, resetToAccount: true);
  void setFrequency(Frequency value) => state = state.copyWith(frequency: value);
  void setNextDueDate(DateTime value) => state = state.copyWith(nextDueDate: value);
  void setEndDate(DateTime? value) => state = state.copyWith(endDate: value);

  // 기존 거래로부터 상태를 초기화하는 새로운 메서드
  void initializeFromTransaction(Transaction transaction, List<Account> allAccounts) {
    final creditEntry = transaction.entries.firstWhere((e) => e.type == EntryType.credit);
    final debitEntry = transaction.entries.firstWhere((e) => e.type == EntryType.debit);

    final fromAcc = allAccounts.firstWhere((a) => a.id == creditEntry.accountId);
    final toAcc = allAccounts.firstWhere((a) => a.id == debitEntry.accountId);

    EntryScreenType type;
    if (fromAcc.type == AccountType.asset && toAcc.type == AccountType.asset) {
      type = EntryScreenType.transfer;
    } else if (fromAcc.type == AccountType.asset || fromAcc.type == AccountType.liability) {
      type = EntryScreenType.expense;
    } else {
      type = EntryScreenType.income;
    }

    state = state.copyWith(
      description: transaction.description,
      amount: debitEntry.amount,
      fromAccount: fromAcc,
      toAccount: toAcc,
      entryType: type,
      // 시작 예정일은 오늘 이후 가장 가까운 날로 설정하거나, 사용자가 선택하도록 둘 수 있습니다.
      // 여기서는 기본값(오늘)을 그대로 사용합니다.
      nextDueDate: DateTime.now(), 
    );
  }
}



// ViewModel을 제공하는 Provider
final repeatingEntryProvider =
    StateNotifierProvider.autoDispose<RepeatingEntryViewModel, RepeatingEntryState>(
  (ref) => RepeatingEntryViewModel(),
);