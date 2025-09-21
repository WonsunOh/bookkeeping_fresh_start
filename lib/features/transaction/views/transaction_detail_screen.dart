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
            // --- 반복 거래로 추가 버튼 ---
            IconButton(
              icon: const Icon(Icons.replay_circle_filled_outlined),
              tooltip: '반복 거래로 추가',
              onPressed: () {
                // 현재 보고 있는 transaction 객체를 extra에 담아서
                // 반복 거래 추가 화면으로 전달합니다.
                asyncTransaction.whenData((transaction) {
                  context.push('/repeating-transactions/entry', extra: transaction);
                });
              },
            ),
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
              onPressed: () async { // 1. async 키워드 추가
                // 2. showDialog가 끝날 때까지 기다리고, 그 결과를 받습니다.
                final bool? shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('삭제 확인'),
                    content: const Text('이 거래를 정말 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        // '취소'를 누르면 false를 반환하고 닫습니다.
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        // '삭제'를 누르면 true를 반환하고 닫습니다.
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('삭제', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (shouldDelete == true) {
                  // --- 👇 여기가 최종 수정의 핵심입니다 ---
                  // 1. 먼저 현재 화면에서 안전하게 벗어납니다.
                  if (context.mounted) {
                    context.go('/');
                  }
                  
                  // 2. 화면을 벗어난 후에 데이터 삭제를 요청합니다.
                  // 이제 UI 충돌이 발생할 수 없습니다.
                  // await을 사용하지 않아도 되지만, 에러 핸들링 등을 위해 유지할 수 있습니다.
                  try {
                    await ref.read(transactionProvider.notifier).deleteTransaction(transactionId);
                  } catch (e) {
                    // 에러가 발생하면 스낵바 대신 콘솔에 로그를 남기거나
                    // 별도의 에러 로깅 서비스를 사용할 수 있습니다.
                    debugPrint("삭제 중 오류 발생: $e");
                  }
                  // ------------------------------------
                }
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          // 화면을 아래로 당기면 이 함수가 실행됩니다.
          onRefresh: () async {
            // 1. transactionProvider를 먼저 새로고침하고 기다립니다.
            ref.refresh(transactionProvider);
            // 2. accountsStreamProvider를 새로고침하고 기다립니다.
            await ref.refresh(accountsStreamProvider.future);
          },
          child: asyncTransaction.when(
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
      ),
    );
  }
}