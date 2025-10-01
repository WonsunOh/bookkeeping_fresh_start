// lib/features/repeating_transactions/views/repeating_transaction_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../../../data/repositories/repeating_transaction_repository.dart';

// 모든 반복 거래 규칙을 실시간으로 제공하는 StreamProvider
final repeatingTransactionsStreamProvider = StreamProvider((ref) {
  final repository = ref.watch(repeatingTransactionRepositoryProvider);
  return repository.watchAll();
});

class RepeatingTransactionListScreen extends ConsumerWidget {
  const RepeatingTransactionListScreen({super.key});

  Future<void> _deleteRepeatingTransaction(
    BuildContext context,
    WidgetRef ref,
    String id,
    String description,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('반복 거래 삭제'),
        content: Text('\'$description\' 반복 거래를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(repeatingTransactionRepositoryProvider);
        await repository.delete(id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('반복 거래가 삭제되었습니다.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRules = ref.watch(repeatingTransactionsStreamProvider);

    return ResponsiveLayout(
      child: Scaffold(
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => context.push(
                          '/repeating-transactions/entry',
                          extra: rule,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRepeatingTransaction(
                          context,
                          ref,
                          rule.id,
                          rule.description,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => context.push('/repeating-transactions/entry', extra: rule),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('오류: $e')),
        ),
      ),
    );
  }
}