// lib/features/budget/viewmodels/budget_viewmodel.dart

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums.dart';
import '../../../data/models/account.dart';
import '../../../data/models/budget.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../transaction/viewmodels/account_provider.dart';
import '../../transaction/viewmodels/transaction_viewmodel.dart';

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

class BudgetViewModel extends Notifier<BudgetState> {
  @override
  BudgetState build() {
    return BudgetState(selectedDate: DateTime.now());
  }

  void changeMonth(int monthOffset) {
    final current = state.selectedDate;
    state = state.copyWith(
      selectedDate: DateTime(current.year, current.month + monthOffset, 1),
    );
  }
}

final budgetViewModelProvider = NotifierProvider<BudgetViewModel, BudgetState>(() {
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

  // 에러 발생 시, 올바른 타입의 AsyncValue.error를 새로 생성하여 반환합니다.
  if (asyncTransactions.hasError) {
    return AsyncValue.error(asyncTransactions.error!, asyncTransactions.stackTrace!);
  }
  if (asyncAccounts.hasError) {
    return AsyncValue.error(asyncAccounts.error!, asyncAccounts.stackTrace!);
  }
  if (asyncBudgets.hasError) {
    return AsyncValue.error(asyncBudgets.error!, asyncBudgets.stackTrace!);
  }

  final transactions = asyncTransactions.value!;
  final accounts = asyncAccounts.value!;
  final budgets = asyncBudgets.value!;

  // 예산 현황 계산 로직 구현
  final List<BudgetStatus> statusList = accounts.map((account) {
    final budget = budgets.firstWhereOrNull((b) => b.accountId == account.id);
    final budgetAmount = budget?.amount ?? 0.0;
    
    // 해당 계정의 지출 계산
    final spentAmount = transactions
        .where((t) => t.date.year == budgetState.year && t.date.month == budgetState.month)
        .expand((t) => t.entries)
        .where((e) => e.accountId == account.id && e.type == EntryType.debit)
        .fold(0.0, (sum, entry) => sum + entry.amount);

    return BudgetStatus(
      account: account,
      budgetAmount: budgetAmount,
      spentAmount: spentAmount,
    );
  }).toList();

  return AsyncValue.data(statusList);
});