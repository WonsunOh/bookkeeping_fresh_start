// lib/data/models/repeating_transaction.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums.dart';

class RepeatingTransaction {
  final String id;
  final String description;
  final double amount;
  final String fromAccountId;
  final String toAccountId;
  final EntryScreenType entryType;
  final Frequency frequency;
  final DateTime nextDueDate;
  final DateTime? endDate;

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

  // 👇 [추가] 'copyWith' 미정의 에러 해결을 위한 메서드
  RepeatingTransaction copyWith({
    String? id,
    String? description,
    double? amount,
    String? fromAccountId,
    String? toAccountId,
    EntryScreenType? entryType,
    Frequency? frequency,
    DateTime? nextDueDate,
    DateTime? endDate,
  }) {
    return RepeatingTransaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      entryType: entryType ?? this.entryType,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
