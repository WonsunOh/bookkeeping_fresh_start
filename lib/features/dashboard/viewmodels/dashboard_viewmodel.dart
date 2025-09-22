// lib/features/dashboard/viewmodels/dashboard_viewmodel.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

import '../../../core/enums.dart';
import '../../../data/models/account.dart';
import '../../../data/models/transaction.dart';
import '../../transaction/viewmodels/account_provider.dart';
import '../../transaction/viewmodels/transaction_viewmodel.dart';

// 대시보드 요약 데이터를 담을 클래스
class DashboardSummary {
  final double totalIncome;
  final double totalExpense;
  double get netIncome => totalIncome - totalExpense;

  DashboardSummary({this.totalIncome = 0.0, this.totalExpense = 0.0});
}

// 외부 패키지 의존성 없이 안전하게 계정 정보를 찾는 함수
Account? _findAccountById(List<Account> accounts, String id) {
  try {
    return accounts.firstWhere((account) => account.id == id);
  } catch (e) {
    return null;
  }
}

// ⭐ [수정] 차트 데이터와 축 제목을 함께 담을 클래스
class BarChartDataWithTitles {
  final List<BarChartGroupData> barGroups;
  final List<String> titles;

  BarChartDataWithTitles({required this.barGroups, required this.titles});
}

// 월별 데이터를 담기 위한 모델 클래스
class MonthlySummary {
  final String monthLabel; // '10월', '11월' 등 차트에 표시될 라벨
  double totalRevenue = 0;
  double totalExpense = 0;

  MonthlySummary({required this.monthLabel});
}

// 1. [기존 로직 개선] 이번 달 요약 정보 Provider
final thisMonthSummaryProvider = Provider.autoDispose<AsyncValue<Map<String, double>>>((ref) {
  final asyncTransactions = ref.watch(transactionProvider);
  final asyncAccounts = ref.watch(accountsStreamProvider);

  if (asyncTransactions is AsyncLoading || asyncAccounts is AsyncLoading) {
    return const AsyncValue.loading();
  }
  final error = asyncTransactions.error ?? asyncAccounts.error;
  if (error != null) {
    return AsyncValue.error(error, StackTrace.current);
  }

  final transactions = asyncTransactions.value!;
  final accounts = asyncAccounts.value!;

  final now = DateTime.now();
  final firstDayOfMonth = DateTime(now.year, now.month, 1);
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

  // 이번 달 거래만 필터링
  final thisMonthTransactions = transactions.where((t) {
    final tDate = DateUtils.dateOnly(t.date);
    return !tDate.isBefore(firstDayOfMonth) && !tDate.isAfter(lastDayOfMonth);
  }).toList();

  double totalRevenue = 0;
  double totalExpense = 0;

  for (final transaction in thisMonthTransactions) {
    for (final entry in transaction.entries) {
      final account = _findAccountById(accounts, entry.accountId);
      if (account == null) continue;

      if (account.type == AccountType.revenue) {
        totalRevenue += (entry.type == EntryType.credit ? entry.amount : -entry.amount);
      } else if (account.type == AccountType.expense) {
        totalExpense += (entry.type == EntryType.debit ? entry.amount : -entry.amount);
      }
    }
  }

  return AsyncValue.data({
    'revenue': totalRevenue,
    'expense': totalExpense,
    'netIncome': totalRevenue - totalExpense,
  });
});


// 2. ⭐ [수정] 월별 바 차트 Provider (데이터와 제목을 함께 반환)
final monthlyBarChartProvider = Provider.autoDispose<AsyncValue<BarChartDataWithTitles>>((ref) {
  final asyncTransactions = ref.watch(transactionProvider);
  final asyncAccounts = ref.watch(accountsStreamProvider);

  if (asyncTransactions is AsyncLoading || asyncAccounts is AsyncLoading) {
    return const AsyncValue.loading();
  }
  final error = asyncTransactions.error ?? asyncAccounts.error;
  if (error != null) {
    return AsyncValue.error(error, StackTrace.current);
  }

  final transactions = asyncTransactions.value!;
  final accounts = asyncAccounts.value!;
  final now = DateTime.now();
  final Map<String, MonthlySummary> summaries = {};

  for (int i = 5; i >= 0; i--) {
    final date = DateTime(now.year, now.month - i, 1);
    final monthKey = DateFormat('yyyy-MM').format(date);
    summaries[monthKey] = MonthlySummary(monthLabel: DateFormat('M월').format(date));
  }

  for (final transaction in transactions) {
    final monthKey = DateFormat('yyyy-MM').format(transaction.date);
    if (summaries.containsKey(monthKey)) {
      for (final entry in transaction.entries) {
        final account = _findAccountById(accounts, entry.accountId);
        if (account == null) continue;
        if (account.type == AccountType.revenue) {
          summaries[monthKey]!.totalRevenue += (entry.type == EntryType.credit ? entry.amount : -entry.amount);
        } else if (account.type == AccountType.expense) {
          summaries[monthKey]!.totalExpense += (entry.type == EntryType.debit ? entry.amount : -entry.amount);
        }
      }
    }
  }

  int x = 0;
  final barGroups = summaries.values.map((summary) {
    return BarChartGroupData(
      x: x++,
      barRods: [
        BarChartRodData(toY: summary.totalExpense, color: Colors.redAccent, width: 14),
        BarChartRodData(toY: summary.totalRevenue, color: Colors.greenAccent, width: 14),
      ],
    );
  }).toList();

  final titles = summaries.values.map((s) => s.monthLabel).toList();

  // ⭐ 데이터와 제목을 함께 담은 객체를 반환
  return AsyncValue.data(BarChartDataWithTitles(barGroups: barGroups, titles: titles));
});


// ⭐ [수정] 이제 거래 유형으로 EntryScreenType을 직접 사용합니다.
class RecentTransactionInfo {
  final Transaction transaction;
  final EntryScreenType type;

  RecentTransactionInfo({required this.transaction, required this.type});
}




// ⭐ [핵심 수정] 최근 거래 내역 Provider
final recentTransactionsProvider = Provider.autoDispose<AsyncValue<List<RecentTransactionInfo>>>((ref) {
  // 계정 정보를 알아야 거래 성격을 파악할 수 있으므로 함께 watch 합니다.
  final asyncTransactions = ref.watch(transactionProvider);
  final asyncAccounts = ref.watch(accountsStreamProvider);

  if (asyncTransactions.isLoading || asyncAccounts.isLoading) {
    return const AsyncValue.loading();
  }
  if (asyncTransactions.hasError || asyncAccounts.hasError) {
    return AsyncValue.error(
      asyncTransactions.error ?? asyncAccounts.error ?? 'Error',
      StackTrace.current,
    );
  }

  final transactions = asyncTransactions.value!;
  final accounts = asyncAccounts.value!;

  transactions.sort((a, b) => b.date.compareTo(a.date));

  final mappedList = transactions.map((transaction) {
    var type = EntryScreenType.transfer; 

    for (final entry in transaction.entries) {
      final account = _findAccountById(accounts, entry.accountId);
      if (account != null) {
        if (entry.type == EntryType.debit && account.type == AccountType.expense) {
          type = EntryScreenType.expense;
          break; 
        }
        if (entry.type == EntryType.credit && account.type == AccountType.revenue) {
          type = EntryScreenType.income;
        }
      }
    }
    return RecentTransactionInfo(transaction: transaction, type: type);
  }).toList();

  // ⭐ 필터링 로직 추가: 거래 유형이 'transfer'가 아닌 것만 남깁니다.
  final filteredList = mappedList.where((info) => info.type != EntryScreenType.transfer).toList();

  return AsyncValue.data(filteredList);
});

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

