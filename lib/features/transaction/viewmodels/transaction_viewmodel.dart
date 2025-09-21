// lib/features/transaction/viewmodels/transaction_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../data/models/transaction.dart';
import '../../../data/repositories/transaction_repository.dart';
import 'home_viewmodel.dart'; // home_viewmodel.dart는 필터링을 위해 필요합니다.

// ViewModel: StateNotifier를 상속받아 상태 관리 로직을 구현합니다.
// StreamSubscription 대신, 필요할 때만 데이터를 불러오는 방식으로 변경합니다.
class TransactionViewModel extends StateNotifier<AsyncValue<List<Transaction>>> {
  final Ref _ref;

  TransactionViewModel(this._ref) : super(const AsyncValue.loading()) {
    // ViewModel이 생성되자마자 거래 목록을 한 번 불러옵니다.
    _fetchTransactions();
  }

  // 거래 목록을 불러와 상태를 업데이트하는 내부 함수
  Future<void> _fetchTransactions() async {
    try {
      final repository = _ref.read(transactionRepositoryProvider);
      final transactions = await repository.watchAllTransactions().first;
      // 데이터 로딩에 성공하면 상태를 AsyncValue.data로 변경
      if (mounted) {
        state = AsyncValue.data(transactions);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  // 거래 추가 로직
  Future<void> addTransaction(Transaction transaction) async {
    final repository = _ref.read(transactionRepositoryProvider);
    await repository.addTransaction(transaction);
    // 데이터 변경이 있었으므로 전체 목록을 다시 불러옵니다. (수동 새로고침)
    await _fetchTransactions();
  }

  // 거래 수정 로직
  Future<void> updateTransaction(Transaction transaction) async {
    final repository = _ref.read(transactionRepositoryProvider);
    await repository.updateTransaction(transaction);
    await _fetchTransactions();
  }

  // 거래 삭제 로직
  Future<void> deleteTransaction(String id) async {
    final repository = _ref.read(transactionRepositoryProvider);
    await repository.deleteTransaction(id);
    await _fetchTransactions();
  }
}

// Provider: StateNotifierProvider
// 이 프로바이더의 이름은 기존 코드와 동일하게 'transactionProvider'로 유지합니다.
final transactionProvider = StateNotifierProvider<TransactionViewModel, AsyncValue<List<Transaction>>>((ref) {
  return TransactionViewModel(ref);
});


// --- 필터링 Provider는 기존 코드를 그대로 사용합니다 ---
final filteredTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((ref) {
  final asyncTransactions = ref.watch(transactionProvider);
  final filters = ref.watch(homeViewModelProvider);

  return asyncTransactions.when(
    data: (transactions) {
      List<Transaction> filteredList = transactions;

      if (filters.dateRange != null) {
        filteredList = filteredList.where((t) {
          return !t.date.isBefore(filters.dateRange!.start) &&
                 !t.date.isAfter(filters.dateRange!.end.add(const Duration(days: 1)));
        }).toList();
      }

      if (filters.searchQuery.isNotEmpty) {
        final query = filters.searchQuery.toLowerCase();
        filteredList = filteredList
            .where((t) => t.description.toLowerCase().contains(query))
            .toList();
      }
      
      return AsyncValue.data(filteredList);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});