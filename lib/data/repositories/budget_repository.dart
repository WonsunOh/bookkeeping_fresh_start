// lib/data/repositories/budget_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';

class BudgetRepository {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('budgets');

  // 특정 연도와 월의 모든 예산 설정을 실시간으로 가져옵니다.
  Stream<List<Budget>> watchBudgetsForMonth(int year, int month) {
    return _collection
        .where('year', isEqualTo: year)
        .where('month', isEqualTo: month)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Budget.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 예산을 설정(추가 또는 수정)합니다.
  // 문서 ID를 "년도-월_계정ID" 형식으로 만들어 중복 설정을 방지합니다.
  Future<void> setBudget(Budget budget) {
    final docId = '${budget.year}-${budget.month}_${budget.accountId}';
    return _collection.doc(docId).set(budget.toFirestore());
  }
}

// Repository를 제공하는 Provider
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});