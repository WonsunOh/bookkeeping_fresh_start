// lib/data/models/journal_entry.dart
import '../../core/enums.dart';

class JournalEntry {
  final String accountId;
  final EntryType type;
  final double amount;

  JournalEntry({
    required this.accountId,
    required this.type,
    required this.amount,
  });

  JournalEntry copyWith({
    String? accountId,
    EntryType? type,
    double? amount,
  }) {
    return JournalEntry(
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JournalEntry &&
        other.accountId == accountId &&
        other.type == type &&
        other.amount == amount;
  }

  @override
  int get hashCode => accountId.hashCode ^ type.hashCode ^ amount.hashCode;

  // Firestore를 위한 메서드 추가
  Map<String, dynamic> toFirestore() {
    return {
      'accountId': accountId,
      'type': type.name,
      'amount': amount,
    };
  }

  factory JournalEntry.fromFirestore(Map<String, dynamic> map) {
    return JournalEntry(
      accountId: map['accountId'] as String,
      type: EntryType.values.firstWhere((e) => e.name == map['type']),
      amount: (map['amount'] as num).toDouble(),
    );
  }
}