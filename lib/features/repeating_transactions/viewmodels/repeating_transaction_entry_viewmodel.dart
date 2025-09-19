// lib/features/repeating_transactions/viewmodels/repeating_transaction_entry_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/enums.dart';
import '../../../data/models/account.dart';
import '../../../data/models/repeating_transaction.dart';

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
}

// ViewModel을 제공하는 Provider
final repeatingEntryProvider =
    StateNotifierProvider.autoDispose<RepeatingEntryViewModel, RepeatingEntryState>(
  (ref) => RepeatingEntryViewModel(),
);