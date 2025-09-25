// lib/features/transaction/viewmodels/transaction_list_filter_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums.dart';
import '../../../data/models/transaction.dart';
import 'account_provider.dart';
import 'transaction_viewmodel.dart';

@immutable
class TransactionListFilterState {
  final String searchQuery;
  final DateTimeRange? dateRange;
  final Set<EntryScreenType>? transactionTypes;
  final String? selectedAccountId;
  final double? minAmount;
  final double? maxAmount;

  const TransactionListFilterState({
    this.searchQuery = '',
    this.dateRange,
    this.transactionTypes,
    this.selectedAccountId,
    this.minAmount,
    this.maxAmount,
  });

  TransactionListFilterState copyWith({
    String? searchQuery,
    DateTimeRange? dateRange,
    Set<EntryScreenType>? transactionTypes,
    String? selectedAccountId,
    double? minAmount,
    double? maxAmount,
    bool clearDateRange = false,
    bool clearTransactionTypes = false,
    bool clearSelectedAccount = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
  }) {
    return TransactionListFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      transactionTypes: clearTransactionTypes ? null : (transactionTypes ?? this.transactionTypes),
      selectedAccountId: clearSelectedAccount ? null : (selectedAccountId ?? this.selectedAccountId),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
    );
  }

  bool hasActiveFilters() {
    return searchQuery.isNotEmpty ||
           dateRange != null ||
           transactionTypes != null ||
           selectedAccountId != null ||
           minAmount != null ||
           maxAmount != null;
  }

  int getActiveFilterCount() {
    int count = 0;
    if (searchQuery.isNotEmpty) count++;
    if (dateRange != null) count++;
    if (transactionTypes != null && transactionTypes!.isNotEmpty) count++;
    if (selectedAccountId != null) count++;
    if (minAmount != null) count++;
    if (maxAmount != null) count++;
    return count;
  }
}

class TransactionListFilterNotifier extends Notifier<TransactionListFilterState> {
  @override
  TransactionListFilterState build() {
    return const TransactionListFilterState();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(dateRange: range);
  }

  void clearDateRange() {
    state = state.copyWith(clearDateRange: true);
  }

  void toggleTransactionType(EntryScreenType type) {
    final currentTypes = state.transactionTypes ?? <EntryScreenType>{};
    final newTypes = Set<EntryScreenType>.from(currentTypes);
    
    if (newTypes.contains(type)) {
      newTypes.remove(type);
    } else {
      newTypes.add(type);
    }
    
    state = state.copyWith(
      transactionTypes: newTypes.isEmpty ? null : newTypes,
      clearTransactionTypes: newTypes.isEmpty,
    );
  }

  void setSelectedAccountId(String? accountId) {
    state = state.copyWith(
      selectedAccountId: accountId,
      clearSelectedAccount: accountId == null,
    );
  }

  void setMinAmount(double? amount) {
    state = state.copyWith(
      minAmount: amount,
      clearMinAmount: amount == null,
    );
  }

  void setMaxAmount(double? amount) {
    state = state.copyWith(
      maxAmount: amount,
      clearMaxAmount: amount == null,
    );
  }

  void clearAllFilters() {
    state = const TransactionListFilterState();
  }
}

final transactionListFilterProvider = NotifierProvider<TransactionListFilterNotifier, TransactionListFilterState>(
  () => TransactionListFilterNotifier(),
);

// 필터링된 거래 목록 Provider
final filteredTransactionListProvider = Provider<AsyncValue<List<Transaction>>>((ref) {
  final asyncTransactions = ref.watch(transactionProvider);
  final asyncAccounts = ref.watch(accountsStreamProvider);
  final filterState = ref.watch(transactionListFilterProvider);

  return asyncTransactions.when(
    data: (transactions) {
      return asyncAccounts.when(
        data: (accounts) {
          List<Transaction> filteredList = transactions;

          // 텍스트 검색 필터
          if (filterState.searchQuery.isNotEmpty) {
            final query = filterState.searchQuery.toLowerCase();
            filteredList = filteredList.where((transaction) {
              // 거래 설명에서 검색
              if (transaction.description.toLowerCase().contains(query)) {
                return true;
              }
              
              // 관련 계정명에서 검색
              for (final entry in transaction.entries) {
                try {
                  final account = accounts.firstWhere((a) => a.id == entry.accountId);
                  if (account.name.toLowerCase().contains(query)) {
                    return true;
                  }
                } catch (e) {
                  // 계정을 찾을 수 없으면 스킵
                  continue;
                }
              }
              
              return false;
            }).toList();
          }

          // 날짜 범위 필터
          if (filterState.dateRange != null) {
            filteredList = filteredList.where((transaction) {
              return !transaction.date.isBefore(filterState.dateRange!.start) &&
                     !transaction.date.isAfter(filterState.dateRange!.end);
            }).toList();
          }

          // 거래 유형 필터
          if (filterState.transactionTypes != null && filterState.transactionTypes!.isNotEmpty) {
            filteredList = filteredList.where((transaction) {
              try {
                final transactionType = _determineTransactionType(transaction, accounts);
                return filterState.transactionTypes!.contains(transactionType);
              } catch (e) {
                return false;
              }
            }).toList();
          }

          // 계정 필터
          if (filterState.selectedAccountId != null) {
            filteredList = filteredList.where((transaction) {
              return transaction.entries.any((entry) => entry.accountId == filterState.selectedAccountId);
            }).toList();
          }

          // 금액 범위 필터
          if (filterState.minAmount != null || filterState.maxAmount != null) {
            filteredList = filteredList.where((transaction) {
              final amount = transaction.entries.first.amount;
              if (filterState.minAmount != null && amount < filterState.minAmount!) {
                return false;
              }
              if (filterState.maxAmount != null && amount > filterState.maxAmount!) {
                return false;
              }
              return true;
            }).toList();
          }

          // 날짜 순으로 정렬 (최신순)
          filteredList.sort((a, b) => b.date.compareTo(a.date));

          return AsyncValue.data(filteredList);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// Helper function for transaction type determination
EntryScreenType _determineTransactionType(Transaction transaction, List accounts) {
  try {
    final debitEntry = transaction.entries.firstWhere((e) => e.type == EntryType.debit);
    final creditEntry = transaction.entries.firstWhere((e) => e.type == EntryType.credit);

    final fromAcc = accounts.firstWhere((a) => a.id == creditEntry.accountId);
    final toAcc = accounts.firstWhere((a) => a.id == debitEntry.accountId);

    if (fromAcc.type == AccountType.asset && toAcc.type == AccountType.asset) {
      return EntryScreenType.transfer;
    } else if (fromAcc.type == AccountType.asset && 
               (toAcc.type == AccountType.expense || toAcc.type == AccountType.liability)) {
      return EntryScreenType.expense;
    } else if ((fromAcc.type == AccountType.revenue || fromAcc.type == AccountType.equity) && 
               toAcc.type == AccountType.asset) {
      return EntryScreenType.income;
    } else {
      return EntryScreenType.expense;
    }
  } catch (e) {
    // 계정을 찾을 수 없는 경우 기본값으로 expense 반환
    return EntryScreenType.expense;
  }
}