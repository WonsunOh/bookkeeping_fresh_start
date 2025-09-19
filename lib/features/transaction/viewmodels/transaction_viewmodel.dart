// lib/features/transaction/viewmodels/transaction_viewmodel.dart

import 'dart:async'; // StreamSubscription을 위해 import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/transaction_repository.dart';
import 'home_viewmodel.dart';

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
    // 1. 이제 Repository의 올바른 메서드인 watchAllTransactions를 사용합니다.
    _subscription = _repository.watchAllTransactions().listen(
      (transactions) {
        state = AsyncValue.data(transactions);
      },
      onError: (e, s) {
        state = AsyncValue.error(e, s);
      },
    );
  }

  // 2. 불필요하고 오류를 유발했던 loadTransactions 메서드를 완전히 삭제했습니다.

  // 거래 추가 (이제 목록 새로고침이 필요 없습니다)
  Future<void> addTransaction(Transaction transaction) async {
    // 에러 처리를 위해 try-catch 블록을 추가합니다.
    try {
      await _repository.addTransaction(transaction);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // 거래 수정
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _repository.updateTransaction(transaction);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // 거래 삭제
  Future<void> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // ViewModel이 소멸될 때 스트림 구독을 반드시 취소하여 메모리 누수를 방지합니다.
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionViewModel, AsyncValue<List<Transaction>>>(
        (ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionViewModel(repository);
});

// --- 새로운 Provider 추가 ---
// 필터링된 거래 목록을 제공하는 Provider
final filteredTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((ref) {
  // 원본 거래 목록의 상태와 필터의 상태를 모두 watch합니다.
  final asyncTransactions = ref.watch(transactionProvider);
  final filters = ref.watch(homeViewModelProvider);

  // 원본 데이터가 로딩 중이거나 에러가 있으면, 그대로 반환합니다.
  if (asyncTransactions is! AsyncData) {
    return asyncTransactions;
  }

  // 데이터가 있을 때 필터링 로직을 적용합니다.
  final transactions = asyncTransactions.value!;
  List<Transaction> filteredList = transactions;

  // 1. 날짜 범위 필터링
  if (filters.dateRange != null) {
    filteredList = filteredList.where((t) {
      return !t.date.isBefore(filters.dateRange!.start) &&
             !t.date.isAfter(filters.dateRange!.end.add(const Duration(days: 1))); // end 날짜 포함
    }).toList();
  }

  // 2. 검색어 필터링 (거래 내용)
  if (filters.searchQuery.isNotEmpty) {
    final query = filters.searchQuery.toLowerCase();
    filteredList = filteredList
        .where((t) => t.description.toLowerCase().contains(query))
        .toList();
  }

  // 필터링된 결과를 AsyncValue.data로 감싸서 반환합니다.
  return AsyncValue.data(filteredList);
});