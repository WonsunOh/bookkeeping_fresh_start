// lib/features/repeating_transactions/views/repeating_transaction_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/repeating_transaction_repository.dart';

// 모든 반복 거래 규칙을 실시간으로 제공하는 StreamProvider
final repeatingTransactionsStreamProvider = StreamProvider((ref) {
  final repository = ref.watch(repeatingTransactionRepositoryProvider);
  return repository.watchAll();
});

class RepeatingTransactionListScreen extends ConsumerWidget {
  const RepeatingTransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRules = ref.watch(repeatingTransactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('반복 거래 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/repeating-transactions/entry'),
          ),
        ],
      ),
      body: asyncRules.when(
        data: (rules) {
          if (rules.isEmpty) {
            return const Center(child: Text('설정된 반복 거래가 없습니다.'));
          }
          return ListView.builder(
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return ListTile(
                title: Text(rule.description),
                subtitle: Text(
                    '다음 예정일: ${DateFormat('yyyy.MM.dd').format(rule.nextDueDate)}'),
                trailing: const Icon(Icons.edit),
                onTap: () => context.push('/repeating-transactions/entry', extra: rule),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('오류: $e')),
      ),
    );
  }
}