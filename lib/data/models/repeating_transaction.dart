// lib/data/models/repeating_transaction.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/enums.dart';

class RepeatingTransaction {
  final String id;
  final String description;
  final double amount;
  final String fromAccountId; // 돈의 출처 계정 ID
  final String toAccountId;   // 돈의 목적지 계정 ID
  final EntryScreenType entryType; // 지출, 수입, 이체 유형
  final Frequency frequency; // 반복 주기
  final DateTime nextDueDate; // 다음에 이 거래가 생성될 날짜
  final DateTime? endDate;    // 이 규칙이 만료되는 날짜 (선택 사항)

  RepeatingTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.fromAccountId,
    required this.toAccountId,
    required this.entryType,
    required this.frequency,
    required this.nextDueDate,
    this.endDate,
  });

  // Firestore와의 데이터 변환을 위한 메서드
  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'amount': amount,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'entryType': entryType.name,
      'frequency': frequency.name,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    };
  }

  factory RepeatingTransaction.fromFirestore(Map<String, dynamic> map, String id) {
    return RepeatingTransaction(
      id: id,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      fromAccountId: map['fromAccountId'] as String,
      toAccountId: map['toAccountId'] as String,
      entryType: EntryScreenType.values.firstWhere((e) => e.name == map['entryType']),
      frequency: Frequency.values.firstWhere((e) => e.name == map['frequency']),
      nextDueDate: (map['nextDueDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
    );
  }
}