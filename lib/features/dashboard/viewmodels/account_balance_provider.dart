// lib/features/dashboard/viewmodels/account_balance_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../core/enums.dart';
import '../../../data/models/account.dart';
import '../../transaction/viewmodels/account_provider.dart';
import '../../transaction/viewmodels/transaction_viewmodel.dart';

// 계좌와 잔액 정보를 함께 담을 클래스
class AccountBalance {
  final Account account;
  final double balance;

  AccountBalance({required this.account, required this.balance});
}

// 자산 계좌별 잔액 목록을 제공하는 Provider
final accountBalanceProvider = Provider<AsyncValue<List<AccountBalance>>>((ref) {
  final asyncTransactions = ref.watch(transactionProvider);
  final asyncAccounts = ref.watch(accountsStreamProvider);

  if (asyncTransactions.isLoading || asyncAccounts.isLoading) {
    return const AsyncValue.loading();
  }
  if (asyncTransactions.hasError || asyncAccounts.hasError) {
    return AsyncValue.error('데이터 로딩 실패', StackTrace.current);
  }

  final transactions = asyncTransactions.value!;
  final accounts = asyncAccounts.value!;
  
  // 자산 계정만 필터링
  final assetAccounts = accounts.where((a) => a.type == AccountType.asset).toList();
  
  final List<AccountBalance> balances = [];

  for (final account in assetAccounts) {
    double currentBalance = 0;
    // 이 계정과 관련된 모든 거래 내역을 찾습니다.
    for (final transaction in transactions) {
      for (final entry in transaction.entries) {
        if (entry.accountId == account.id) {
          if (entry.type == EntryType.debit) { // 자산 증가 (차변)
            currentBalance += entry.amount;
          } else { // 자산 감소 (대변)
            currentBalance -= entry.amount;
          }
        }
      }
    }
    balances.add(AccountBalance(account: account, balance: currentBalance));
  }
  
  // 잔액이 큰 순서대로 정렬
  balances.sort((a, b) => b.balance.compareTo(a.balance));

  return AsyncValue.data(balances);
});