// lib/data/models/transaction.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'journal_entry.dart';

class Transaction {
  final String id;
  final DateTime date;
  final String description;
  final List<JournalEntry> entries;

  Transaction({
    required this.id,
    required this.date,
    required this.description,
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
}