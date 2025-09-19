// lib/data/repositories/account_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account.dart';

class AccountRepository {
  // Firestore의 'accounts' 컬렉션을 참조합니다.
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('accounts');

  // 모든 계정과목 목록을 실시간 스트림(Stream) 형태로 가져옵니다.
  Stream<List<Account>> watchAllAccounts() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Firestore 문서를 Account 모델 객체로 변환합니다.
        return Account.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 새로운 계정과목을 추가합니다.
  Future<void> addAccount(Account account) {
    return _collection.doc(account.id).set(account.toFirestore());
  }

  // 기존 계정과목을 수정합니다.
  Future<void> updateAccount(Account account) {
    return _collection.doc(account.id).update(account.toFirestore());
  }

  // 계정과목을 삭제합니다.
  Future<void> deleteAccount(String id) {
    return _collection.doc(id).delete();
  }
}