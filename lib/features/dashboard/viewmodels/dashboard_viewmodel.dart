// lib/features/dashboard/viewmodels/dashboard_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../../../core/enums.dart';
import '../../transaction/viewmodels/account_provider.dart';
import '../../transaction/viewmodels/transaction_viewmodel.dart';

// 대시보드 요약 데이터를 담을 클래스
class DashboardSummary {
  final double totalIncome;
  final double totalExpense;
  double get netIncome => totalIncome - totalExpense;

  DashboardSummary({this.totalIncome = 0.0, this.totalExpense = 0.0});
}

// '이번 달'의 요약 데이터를 계산하는 Provider
final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final asyncTransactions = ref.watch(transactionProvider);
  final asyncAccounts = ref.watch(accountsStreamProvider);

  // 데이터가 준비되지 않았으면 해당 상태를 그대로 반환
  if (asyncTransactions.isLoading || asyncAccounts.isLoading) {
    return const AsyncValue.loading();
  }
  if (asyncTransactions.hasError || asyncAccounts.hasError) {
    return AsyncValue.error('데이터 로딩 실패', StackTrace.current);
  }

  final transactions = asyncTransactions.value!;
  final accounts = asyncAccounts.value!;
  
  // '이번 달'에 해당하는 거래만 필터링
  final now = DateTime.now();
  final firstDayOfMonth = DateTime(now.year, now.month, 1);
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

  final thisMonthTransactions = transactions.where((t) {
    return !t.date.isBefore(firstDayOfMonth) && !t.date.isAfter(lastDayOfMonth);
  }).toList();

  double totalIncome = 0;
  double totalExpense = 0;

  for (final transaction in thisMonthTransactions) {
    final toAccountEntry = transaction.entries.firstWhere((e) => e.type == EntryType.debit);
    final toAccount = accounts.firstWhereOrNull((a) => a.id == toAccountEntry.accountId);

    if (toAccount != null) {
      if (toAccount.type == AccountType.expense) {
        totalExpense += toAccountEntry.amount;
      }
    }
    
    final fromAccountEntry = transaction.entries.firstWhere((e) => e.type == EntryType.credit);
    final fromAccount = accounts.firstWhereOrNull((a) => a.id == fromAccountEntry.accountId);
    
    if (fromAccount != null) {
      if (fromAccount.type == AccountType.revenue) {
        totalIncome += fromAccountEntry.amount;
      }
    }
  }

  return AsyncValue.data(DashboardSummary(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
  ));
});