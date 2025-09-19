// lib/features/budget/viewmodels/budget_viewmodel.dart

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/enums.dart';
import '../../../data/models/account.dart';
import '../../../data/models/budget.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../transaction/viewmodels/account_provider.dart';
import '../../transaction/viewmodels/transaction_viewmodel.dart';

// BudgetState와 BudgetViewModel은 이전과 동일합니다.
@immutable
class BudgetState {
  final DateTime selectedDate;
  int get year => selectedDate.year;
  int get month => selectedDate.month;

  const BudgetState({required this.selectedDate});

  BudgetState copyWith({DateTime? selectedDate}) {
    return BudgetState(selectedDate: selectedDate ?? this.selectedDate);
  }
}

class BudgetViewModel extends StateNotifier<BudgetState> {
  BudgetViewModel() : super(BudgetState(selectedDate: DateTime.now()));

  void changeMonth(int monthOffset) {
    final current = state.selectedDate;
    state = state.copyWith(
      selectedDate: DateTime(current.year, current.month + monthOffset, 1),
    );
  }
}

final budgetViewModelProvider =
    StateNotifierProvider<BudgetViewModel, BudgetState>((ref) {
  return BudgetViewModel();
});

// 예산 현황 계산 로직
class BudgetStatus {
  final Account account;
  final double budgetAmount;
  final double spentAmount;
  double get remainingAmount => budgetAmount - spentAmount;
  double get spendingRate => budgetAmount == 0 ? 0 : (spentAmount / budgetAmount);

  BudgetStatus({
    required this.account,
    this.budgetAmount = 0,
    this.spentAmount = 0,
  });
}

final monthlyBudgetsProvider = StreamProvider.autoDispose.family<List<Budget>, DateTime>((ref, date) {
  final budgetRepo = ref.watch(budgetRepositoryProvider);
  return budgetRepo.watchBudgetsForMonth(date.year, date.month);
});

final monthlyBudgetStatusProvider = Provider.autoDispose<AsyncValue<List<BudgetStatus>>>((ref) {
  final budgetState = ref.watch(budgetViewModelProvider);
  final asyncTransactions = ref.watch(transactionProvider);
  final asyncAccounts = ref.watch(accountsStreamProvider);
  final asyncBudgets = ref.watch(monthlyBudgetsProvider(budgetState.selectedDate));

  if (asyncTransactions.isLoading || asyncAccounts.isLoading || asyncBudgets.isLoading) {
    return const AsyncValue.loading();
  }

  // --- 해결책: 에러 발생 시, 올바른 타입의 AsyncValue.error를 새로 생성하여 반환합니다. ---
  if (asyncTransactions.hasError) {
    return AsyncValue.error(asyncTransactions.error!, asyncTransactions.stackTrace!);
  }
  if (asyncAccounts.hasError) {
    return AsyncValue.error(asyncAccounts.error!, asyncAccounts.stackTrace!);
  }
  if (asyncBudgets.hasError) {
    return AsyncValue.error(asyncBudgets.error!, asyncBudgets.stackTrace!);
  }
  // ------------------------------------------------------------------------------------

  final allTransactions = asyncTransactions.value!;
  final allAccounts = asyncAccounts.value!;
  final budgets = asyncBudgets.value!;
  final expenseAccounts = allAccounts.where((a) => a.type == AccountType.expense).toList();

  final monthlyTransactions = allTransactions.where((t) {
    return t.date.year == budgetState.year && t.date.month == budgetState.month;
  }).toList();

  final List<BudgetStatus> statusList = [];
  for (final account in expenseAccounts) {
    final budget = budgets.firstWhere(
      (b) => b.accountId == account.id,
      orElse: () => Budget(id: '', accountId: account.id, year: budgetState.year, month: budgetState.month, amount: 0),
    );

    double spent = 0;
    for (final transaction in monthlyTransactions) {
      final debitEntry = transaction.entries.firstWhereOrNull((e) => e.type == EntryType.debit);
      if (debitEntry != null && debitEntry.accountId == account.id) {
        spent += debitEntry.amount;
      }
    }

    statusList.add(BudgetStatus(
      account: account,
      budgetAmount: budget.amount,
      spentAmount: spent,
    ));
  }
  
  return AsyncValue.data(statusList);
});