// lib/data/models/transaction.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/enums.dart';
import 'account.dart';
import 'journal_entry.dart';

@immutable
class Transaction {
  final String id;
  final String description;
  final DateTime date;
  final List<JournalEntry> entries;

  const Transaction({
    required this.id,
    required this.description,
    required this.date,
    required this.entries,
  });


 

  Transaction copyWith({
    String? id,
    DateTime? date,
    String? description,
    List<JournalEntry>? entries,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      entries: entries ?? this.entries,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction &&
        other.id == id &&
        other.date == date &&
        other.description == description &&
        other.entries == entries;
  }

  @override
  int get hashCode =>
      id.hashCode ^ date.hashCode ^ description.hashCode ^ entries.hashCode;

  // Firestore를 위한 메서드 추가
  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date), // DateTime은 Timestamp로 변환
      'description': description,
      'entries': entries.map((e) => e.toFirestore()).toList(),
    };
  }

  factory Transaction.fromFirestore(Map<String, dynamic> map, String id) {
    return Transaction(
      id: id,
      date: (map['date'] as Timestamp).toDate(), // Timestamp를 DateTime으로 변환
      description: map['description'] as String,
      entries: List<JournalEntry>.from(
        (map['entries'] as List<dynamic>).map(
          (item) => JournalEntry.fromFirestore(item as Map<String, dynamic>),
        ),
      ),
    );
  }
  EntryScreenType getTransactionType(List<Account> accounts) {
  final debitEntry = entries.firstWhere((e) => e.type == EntryType.debit);
  final creditEntry = entries.firstWhere((e) => e.type == EntryType.credit);
  
  final fromAcc = accounts.firstWhere((a) => a.id == creditEntry.accountId);
  final toAcc = accounts.firstWhere((a) => a.id == debitEntry.accountId);
  
  // transaction_entry_viewmodel.dart의 initializeForEdit와 동일한 로직 사용
  if (fromAcc.type == AccountType.asset && toAcc.type == AccountType.asset) {
    return EntryScreenType.transfer;
  } else if (fromAcc.type == AccountType.asset && 
             (toAcc.type == AccountType.expense || toAcc.type == AccountType.liability)) {
    return EntryScreenType.expense;
  } else if ((fromAcc.type == AccountType.revenue || fromAcc.type == AccountType.equity) && 
             toAcc.type == AccountType.asset) {
    return EntryScreenType.income;
  } else {
    return EntryScreenType.expense; // 기본값
  }
}
}

 