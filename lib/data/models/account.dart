// lib/data/models/account.dart
import 'package:equatable/equatable.dart';

import '../../core/enums.dart';

class Account extends Equatable {
  final String id;
  final String name;
  final AccountType type;

  const Account({
    required this.id,
    required this.name,
    required this.type,
  });

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account &&
        other.id == id &&
        other.name == name &&
        other.type == type;
  }
  @override
  List<Object?> get props => [id];

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ type.hashCode;

  // Firestore를 위한 메서드 추가
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.name,
    };
  }

  factory Account.fromFirestore(Map<String, dynamic> map, String id) {
    return Account(
      id: id,
      name: map['name'] as String,
      type: AccountType.values.firstWhere((e) => e.name == map['type']),
    );
  }
}