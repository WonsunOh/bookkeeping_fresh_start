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
  final EntryScreenType? entryType; // 추가

  const Transaction({
    required this.id,
    required this.description,
    required this.date,
    required this.entries,
    this.entryType, // 추가
  });

  Transaction copyWith({
    String? id,
    DateTime? date,
    String? description,
    List<JournalEntry>? entries,
    EntryScreenType? entryType, // 추가
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      entries: entries ?? this.entries,
      entryType: entryType ?? this.entryType, // 추가
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction &&
        other.id == id &&
        other.date == date &&
        other.description == description &&
        other.entries == entries &&
        other.entryType == entryType; // 추가
  }

  @override
  int get hashCode =>
      id.hashCode ^ date.hashCode ^ description.hashCode ^ entries.hashCode ^ entryType.hashCode; // 수정

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'description': description,
      'entries': entries.map((e) => e.toFirestore()).toList(),
      'entryType': entryType?.name, // 추가 (enum의 name 저장)
    };
  }

  factory Transaction.fromFirestore(Map<String, dynamic> map, String id) {
    EntryScreenType? parsedEntryType;
    if (map['entryType'] != null) {
      try {
        parsedEntryType = EntryScreenType.values.firstWhere(
          (e) => e.name == map['entryType'],
        );
      } catch (e) {
        parsedEntryType = null;
      }
    }
    
    return Transaction(
      id: id,
      date: (map['date'] as Timestamp).toDate(),
      description: map['description'] as String,
      entries: List<JournalEntry>.from(
        (map['entries'] as List<dynamic>).map(
          (item) => JournalEntry.fromFirestore(item as Map<String, dynamic>),
        ),
      ),
      entryType: parsedEntryType, // 추가
    );
  }
  
  EntryScreenType getTransactionType(List<Account> accounts) {
    // entryType이 이미 저장되어 있으면 그대로 반환
    if (entryType != null) {
      return entryType!;
    }
    
    // 저장되어 있지 않으면 추측 (구버전 데이터 호환용)
    final debitEntry = entries.firstWhere((e) => e.type == EntryType.debit);
    final creditEntry = entries.firstWhere((e) => e.type == EntryType.credit);
    
    final fromAcc = accounts.firstWhere((a) => a.id == creditEntry.accountId);
    final toAcc = accounts.firstWhere((a) => a.id == debitEntry.accountId);
    
    if (fromAcc.type == AccountType.asset && toAcc.type == AccountType.asset) {
      return EntryScreenType.transfer;
    } else if (fromAcc.type == AccountType.asset && 
               (toAcc.type == AccountType.expense || toAcc.type == AccountType.liability)) {
      return EntryScreenType.expense;
    } else if ((fromAcc.type == AccountType.revenue || fromAcc.type == AccountType.equity) && 
               toAcc.type == AccountType.asset) {
      return EntryScreenType.income;
    } else {
      return EntryScreenType.expense;
    }
  }
}