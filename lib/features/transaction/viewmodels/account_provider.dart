// lib/features/transaction/viewmodels/account_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/enums.dart';
// 1. Drift의 Account가 아닌, 우리 앱의 Account 모델을 import 합니다.
import '../../../data/models/account.dart';
import '../../../data/repositories/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

// 2. 이제 이 Provider는 정확히 우리 앱의 Account 모델 리스트를 제공합니다.
final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchAllAccounts();
});

// 3. 이 Provider는 이제 자동으로 올바른 Account 타입을 사용하게 됩니다.
final accountsByTypeProvider = Provider.family<List<Account>, AccountType>((ref, type) {
  final asyncAccounts = ref.watch(accountsStreamProvider);
  
  return asyncAccounts.when(
    data: (accounts) => accounts.where((account) => account.type == type).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

// --- 데이터 조작(CUD) 계층 ---

// 3. 계정과목 추가/수정/삭제 로직을 담당하는 ViewModel
class AccountViewModel extends Notifier<void> {
  late AccountRepository _repository;

  @override
  void build() {
    _repository = ref.read(accountRepositoryProvider);
  }

  Future<void> addAccount({required String name, required AccountType type}) async {
    final newAccount = Account(
      id: const Uuid().v4(),
      name: name,
      type: type,
    );
    await _repository.addAccount(newAccount);
  }

  Future<void> updateAccount({
    required String id,
    required String name,
    required AccountType type,
  }) async {
    final updatedAccount = Account(id: id, name: name, type: type);
    await _repository.updateAccount(updatedAccount);
  }

  Future<void> deleteAccount(String id) async {
    await _repository.deleteAccount(id);
  }
}

// 4. UI가 AccountViewModel의 메서드를 호출할 수 있도록 Provider를 생성
final accountViewModelProvider = NotifierProvider<AccountViewModel, void>(
  AccountViewModel.new,
);