// lib/data/models/budget.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id; // 문서 ID (예: "2024-09_expense_food")
  final String accountId; // 예산이 설정된 비용 계정과목 ID
  final int year;
  final int month;
  final double amount; // 예산 금액

  Budget({
    required this.id,
    required this.accountId,
    required this.year,
    required this.month,
    required this.amount,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'accountId': accountId,
      'year': year,
      'month': month,
      'amount': amount,
    };
  }

  factory Budget.fromFirestore(Map<String, dynamic> map, String id) {
    return Budget(
      id: id,
      accountId: map['accountId'] as String,
      year: map['year'] as int,
      month: map['month'] as int,
      amount: (map['amount'] as num).toDouble(),
    );
  }
}