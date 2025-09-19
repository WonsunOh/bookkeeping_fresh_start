// lib/features/transaction/views/transaction_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums.dart'; // EntryType을 위해 추가
import '../../../core/widgets/responsive_layout.dart';
import '../../../data/models/account.dart'; // Account 모델을 위해 추가
import '../../../data/models/transaction.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../viewmodels/account_provider.dart';

// 특정 ID의 거래 하나만 불러오는 Provider.family
final transactionDetailProvider = FutureProvider.family<Transaction, String>((ref, id) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactionById(id);
});

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTransaction = ref.watch(transactionDetailProvider(transactionId));
    // 계정 목록을 비동기(StreamProvider)로 가져옵니다.
    final asyncAccounts = ref.watch(accountsStreamProvider);

    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // --- 해결책: pop() 대신 go('/')를 사용하여 홈으로 돌아가도록 수정 ---
          onPressed: () => context.go('/'),
          // --------------------------------------------------------
        ),
          title: const Text('거래 상세 정보'),
          actions: [
            // 수정 버튼
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // 수정 화면으로 이동. transaction 객체를 extra로 전달
                asyncTransaction.whenData((transaction) {
                  context.go('/entry', extra: transaction);
                });
              },
            ),
            // 삭제 버튼
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('삭제 확인'),
                    content: const Text('이 거래를 정말 삭제하시겠습니까?'),
                    actions: [
                      TextButton(onPressed: () => context.pop(), child: const Text('취소')),
                      TextButton(
                        onPressed: () {
                          ref.read(transactionProvider.notifier).deleteTransaction(transactionId);
                          context.pop(); // 다이얼로그 닫기
                          context.pop(); // 상세 화면 닫기
                        },
                        child: const Text('삭제', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: asyncTransaction.when(
          data: (transaction) {
            return asyncAccounts.when(
              data: (allAccounts) {
                final debitEntry = transaction.entries.firstWhere((e) => e.type == EntryType.debit);
                final creditEntry = transaction.entries.firstWhere((e) => e.type == EntryType.credit);
      
                String getAccountName(String id) {
                  return allAccounts.firstWhere((acc) => acc.id == id, orElse: () => Account(id: '', name: '알 수 없음', type: AccountType.asset)).name;
                }
      
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('날짜'),
                  subtitle: Text('${transaction.date.toLocal()}'.split(' ')[0]),
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('내용'),
                  subtitle: Text(transaction.description),
                ),
                ListTile(
                  leading: const Icon(Icons.money),
                  title: const Text('금액'),
                  subtitle: Text('${creditEntry.amount.toInt()}원'),
                ),
                const Divider(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('분개 정보', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_forward, color: Colors.green),
                  title: const Text('차변 (Debit)'),
                  subtitle: Text(getAccountName(debitEntry.accountId)),
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_back, color: Colors.red),
                  title: const Text('대변 (Credit)'),
                  subtitle: Text(getAccountName(creditEntry.accountId)),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('계정 목록을 불러오는 데 실패했습니다: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('거래 정보를 불러오는 데 실패했습니다: $err')),
        ),
      ),
    );
  }
}