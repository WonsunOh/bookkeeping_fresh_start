// lib/data/repositories/repeating_transaction_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/repeating_transaction.dart';

class RepeatingTransactionRepository {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('repeating_transactions');

  // 모든 반복 거래 규칙을 실시간으로 가져옵니다.
  Stream<List<RepeatingTransaction>> watchAll() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RepeatingTransaction.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
  
  // 새로운 반복 거래 규칙을 추가합니다.
  Future<void> add(RepeatingTransaction rule) {
    return _collection.doc(rule.id).set(rule.toFirestore());
  }
  
  // 반복 거래 규칙을 수정합니다.
  Future<void> update(RepeatingTransaction rule) {
    return _collection.doc(rule.id).update(rule.toFirestore());
  }

  // 반복 거래 규칙을 삭제합니다.
  Future<void> delete(String id) {
    return _collection.doc(id).delete();
  }
}

// Repository를 제공하는 Provider
final repeatingTransactionRepositoryProvider =
    Provider<RepeatingTransactionRepository>((ref) {
  return RepeatingTransactionRepository();
});