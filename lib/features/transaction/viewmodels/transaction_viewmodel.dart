// lib/features/transaction/viewmodels/transaction_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/transaction_repository.dart';
import 'home_viewmodel.dart';

// StreamProvider를 직접 사용하여 거래 데이터를 스트리밍합니다
final transactionProvider = StreamProvider<List<Transaction>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchAllTransactions();
});

// 거래 조작을 위한 별도의 서비스 클래스
class TransactionService {
  final TransactionRepository _repository;
  
  TransactionService(this._repository);

  Future<void> addTransaction(Transaction transaction) async {
    await _repository.addTransaction(transaction);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _repository.updateTransaction(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
  }
}

// 서비스 Provider
final transactionServiceProvider = Provider<TransactionService>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionService(repository);
});

// 필터링 Provider
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

