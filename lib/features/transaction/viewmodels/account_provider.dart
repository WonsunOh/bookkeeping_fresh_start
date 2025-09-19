// lib/features/transaction/viewmodels/account_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
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