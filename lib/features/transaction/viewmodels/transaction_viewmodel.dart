// lib/features/transaction/viewmodels/transaction_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // legacy.dart는 필요 없을 수 있습니다.
import '../../../data/models/transaction.dart';
import '../../../data/repositories/transaction_repository.dart';
import 'home_viewmodel.dart';

// ViewModel: StateNotifier를 사용하여 상태를 관리합니다.
// Firestore의 Stream을 구독(listen)하여 데이터 변경을 실시간으로 감지합니다.
class TransactionViewModel extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository _repository;
  StreamSubscription<List<Transaction>>? _subscription;

  TransactionViewModel(this._repository) : super(const AsyncValue.loading()) {
    // ViewModel이 생성되자마자 스트림을 구독합니다.
    _listenToTransactions();
  }

  // Firestore의 거래 데이터 스트림을 구독하고 상태를 업데이트하는 메서드
  void _listenToTransactions() {
    _subscription?.cancel();
    _subscription = _repository.watchAllTransactions().listen(
      (transactions) {
        // 스트림에서 새로운 데이터가 올 때마다 상태를 업데이트합니다.
        if (mounted) {
          state = AsyncValue.data(transactions);
        }
      },
      onError: (e, s) {
        if (mounted) {
          state = AsyncValue.error(e, s);
        }
      },
    );
  }

  // 거래 추가 (데이터 추가만 하면 스트림이 자동으로 UI를 업데이트합니다)
  Future<void> addTransaction(Transaction transaction) async {
    await _repository.addTransaction(transaction);
  }

  // 거래 수정
  Future<void> updateTransaction(Transaction transaction) async {
    await _repository.updateTransaction(transaction);
  }

  // 거래 삭제
  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
  }

  // ViewModel이 소멸될 때 스트림 구독을 반드시 취소하여 메모리 누수를 방지합니다.
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// Provider: StateNotifierProvider
final transactionProvider =
    StateNotifierProvider<TransactionViewModel, AsyncValue<List<Transaction>>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionViewModel(repository);
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