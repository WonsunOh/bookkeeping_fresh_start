// lib/data/repositories/transaction_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';

class TransactionRepository {
  // Firestore의 'transactions' 컬렉션을 참조합니다.
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('transactions');

  // 모든 거래를 데이터베이스에서 가져오는 메서드
  Stream<List<Transaction>> watchAllTransactions() {
    return _collection
        .orderBy('date', descending: true) // 최신순으로 정렬
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Transaction.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 특정 ID의 거래 하나만 가져오는 메서드
  Future<Transaction> getTransactionById(String id) async {
    final doc = await _collection.doc(id).get();
    return Transaction.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
  }

  // 새로운 거래를 데이터베이스에 추가하는 메서드
  Future<void> addTransaction(Transaction transaction) {
    return _collection.doc(transaction.id).set(transaction.toFirestore());
  }

  // 거래를 수정하는 메서드
  Future<void> updateTransaction(Transaction transaction) {
    return _collection.doc(transaction.id).update(transaction.toFirestore());
  }

  // 거래를 삭제하는 메서드
  Future<void> deleteTransaction(String id) {
    return _collection.doc(id).delete();
  }
}

// --- 해결책: 이 Provider 정의를 파일 맨 아래에 추가합니다 ---
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});