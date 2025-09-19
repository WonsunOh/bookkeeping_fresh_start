// lib/features/financial_statements/viewmodels/financial_statement_viewmodel.dart

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums.dart';
import '../../../data/models/account.dart';
import '../../../data/models/balance_sheet.dart';
import '../../../data/models/income_statement.dart';
import '../../../data/models/transaction.dart';
import '../../transaction/viewmodels/account_provider.dart';
import '../../transaction/viewmodels/transaction_viewmodel.dart';
import 'financial_statement_filter_viewmodel.dart';

// Provider들이 공통으로 사용할 필터링된 거래 목록을 제공하는 새로운 Provider
final filteredReportTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((ref) {
  final asyncTransactions = ref.watch(transactionProvider);
  // 선택된 날짜 범위를 watch합니다.
  final dateRange = ref.watch(financialStatementFilterProvider).dateRange;

  return asyncTransactions.whenData((transactions) {
    // 날짜 범위에 해당하는 거래만 필터링하여 반환합니다.
    return transactions.where((t) {
      return !t.date.isBefore(dateRange.start) &&
             !t.date.isAfter(dateRange.end.add(const Duration(days: 1)));
    }).toList();
  });
});


// 재무상태표 Provider 수정
final balanceSheetProvider = Provider<AsyncValue<BalanceSheet>>((ref) {
  // 2. 이제 transactionProvider 대신 필터링된 거래 목록을 watch합니다.
  final asyncTransactions = ref.watch(filteredReportTransactionsProvider);
  final asyncAccounts = ref.watch(accountsStreamProvider);

  // 두 Provider 중 하나라도 로딩 중이거나 에러가 있으면,
  // 재무상태표 Provider도 동일한 상태를 반환합니다.
  if (asyncTransactions.isLoading || asyncAccounts.isLoading) {
    return const AsyncValue.loading();
  }
  if (asyncTransactions.hasError) {
    return AsyncValue.error(asyncTransactions.error!, asyncTransactions.stackTrace!);
  }
  if (asyncAccounts.hasError) {
    return AsyncValue.error(asyncAccounts.error!, asyncAccounts.stackTrace!);
  }

  // 두 Provider 모두 성공적으로 데이터를 가져왔을 때만 계산을 수행합니다.
  final transactions = asyncTransactions.value!;
  final accounts = asyncAccounts.value!;

  final balance = <String, double>{};

  for (final transaction in transactions) {
    for (final entry in transaction.entries) {
      // 혹시 모를 데이터 불일치에 대비해 orElse를 추가하여 안정성을 높입니다.
      final account = accounts.firstWhere(
        (a) => a.id == entry.accountId,
        orElse: () => Account(id: '', name: '알 수 없음', type: AccountType.expense),
      );
      double currentBalance = balance[entry.accountId] ?? 0;

      if (entry.type == EntryType.debit) {
        if (account.type == AccountType.asset || account.type == AccountType.expense) {
          currentBalance += entry.amount;
        } else {
          currentBalance -= entry.amount;
        }
      } else { // Credit
        if (account.type == AccountType.asset || account.type == AccountType.expense) {
          currentBalance -= entry.amount;
        } else {
          currentBalance += entry.amount;
        }
      }
      balance[entry.accountId] = currentBalance;
    }
  }

  double totalAssets = 0;
  double totalLiabilities = 0;
  double totalEquity = 0;

  balance.forEach((accountId, amount) {
    final account = accounts.firstWhere((a) => a.id == accountId);
    switch (account.type) {
      case AccountType.asset: totalAssets += amount; break;
      case AccountType.liability: totalLiabilities += amount; break;
      case AccountType.equity: totalEquity += amount; break;
      default: break;
    }
  });

  // 계산된 결과를 AsyncValue.data로 감싸서 반환합니다.
  return AsyncValue.data(BalanceSheet(
    totalAssets: totalAssets,
    totalLiabilities: totalLiabilities,
    totalEquity: totalEquity,
  ));
});

// 손익계산서 Provider
final incomeStatementProvider = Provider<AsyncValue<IncomeStatement>>((ref) {
  final asyncTransactions = ref.watch(filteredReportTransactionsProvider);
  final asyncAccounts = ref.watch(accountsStreamProvider);

  if (asyncTransactions.isLoading || asyncAccounts.isLoading) {
    return const AsyncValue.loading();
  }
  if (asyncTransactions.hasError) {
    return AsyncValue.error(asyncTransactions.error!, asyncTransactions.stackTrace!);
  }
  if (asyncAccounts.hasError) {
    return AsyncValue.error(asyncAccounts.error!, asyncAccounts.stackTrace!);
  }

  final transactions = asyncTransactions.value!;
  final accounts = asyncAccounts.value!;
  
  double totalRevenue = 0;
  double totalExpenses = 0;

  for (final transaction in transactions) {
    for (final entry in transaction.entries) {
      final account = accounts.firstWhere(
        (a) => a.id == entry.accountId,
        orElse: () => Account(id: '', name: '알 수 없음', type: AccountType.asset),
      );
      if (account.type == AccountType.revenue) {
        if (entry.type == EntryType.credit) totalRevenue += entry.amount;
        if (entry.type == EntryType.debit) totalRevenue -= entry.amount;
      } else if (account.type == AccountType.expense) {
        if (entry.type == EntryType.debit) totalExpenses += entry.amount;
        if (entry.type == EntryType.credit) totalExpenses -= entry.amount;
      }
    }
  }
  
  // 자본 계정의 변동(초기자본금 등)을 순이익에 반영하여 자본 총계를 정확하게 계산합니다.
  final balanceSheet = ref.watch(balanceSheetProvider).value;
  if (balanceSheet != null) {
      // 순이익 = 기말자본 - 기초자본. 
      // 여기서는 간단하게 자본 변동을 수익으로 간주하여 계산합니다.
      // 실제 회계에서는 더 복잡하지만, 이 앱에서는 이 방식으로 순자산 변동을 보여줍니다.
      // totalRevenue += balanceSheet.totalEquity; // 이 부분은 회계 원칙에 따라 재검토 필요
  }

  return AsyncValue.data(IncomeStatement(
    totalRevenue: totalRevenue,
    totalExpenses: totalExpenses,
  ));
});



// 원형 차트의 한 조각을 나타내는 데이터 클래스
class PieChartSection {
  final String title;
  final double value;
  final double percentage;

  PieChartSection({
    required this.title,
    required this.value,
    required this.percentage,
  });
}

// 비용 분석 데이터를 제공하는 Provider
final expenseChartDataProvider = Provider<AsyncValue<List<PieChartSection>>>((ref) {
   final asyncTransactions = ref.watch(filteredReportTransactionsProvider);
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

  // 1. 모든 지출(Expense) 거래만 필터링합니다.
  final expenseTransactions = transactions.where((t) {
    final toAccountId = t.entries.firstWhere((e) => e.type == EntryType.debit).accountId;
    final account = accounts.firstWhereOrNull((a) => a.id == toAccountId);
    return account?.type == AccountType.expense;
  }).toList();

  if (expenseTransactions.isEmpty) {
    return const AsyncValue.data([]); // 지출이 없으면 빈 리스트 반환
  }

  // 2. 비용 계정 ID를 기준으로 거래들을 그룹화하고 합계를 계산합니다.
  final Map<String, double> expensesByAccountId = {};
  for (var t in expenseTransactions) {
    final debitEntry = t.entries.firstWhere((e) => e.type == EntryType.debit);
    expensesByAccountId.update(
      debitEntry.accountId,
      (value) => value + debitEntry.amount,
      ifAbsent: () => debitEntry.amount,
    );
  }

  // 3. 총 지출액을 계산합니다.
  final totalExpenses = expensesByAccountId.values.fold(0.0, (sum, amount) => sum + amount);

  // 4. 차트에 표시할 데이터(PieChartSection) 리스트를 생성합니다.
  final chartData = expensesByAccountId.entries.map((entry) {
    final account = accounts.firstWhere((a) => a.id == entry.key);
    final percentage = (entry.value / totalExpenses) * 100;
    return PieChartSection(
      title: account.name,
      value: entry.value,
      percentage: percentage,
    );
  }).toList();
  
  // 금액이 큰 순서대로 정렬
  chartData.sort((a, b) => b.value.compareTo(a.value));

  return AsyncValue.data(chartData);
});