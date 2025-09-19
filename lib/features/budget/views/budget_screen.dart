// lib/features/budget/views/budget_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/budget_repository.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../../../data/models/budget.dart';
import '../viewmodels/budget_viewmodel.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetViewModelProvider);
    final budgetViewModel = ref.read(budgetViewModelProvider.notifier);
    final asyncStatus = ref.watch(monthlyBudgetStatusProvider);

    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(title: const Text('월별 예산 설정')),
        body: Column(
          children: [
            // --- 월 선택 UI ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => budgetViewModel.changeMonth(-1),
                ),
                Text(
                  DateFormat('yyyy년 MM월').format(budgetState.selectedDate),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => budgetViewModel.changeMonth(1),
                ),
              ],
            ),
            const Divider(),
            // --- 예산 목록 UI ---
            Expanded(
              child: asyncStatus.when(
                data: (statuses) {
                  if (statuses.isEmpty) {
                    return const Center(child: Text('예산을 설정할 비용 계정과목이 없습니다.'));
                  }
                  return ListView.builder(
                    itemCount: statuses.length,
                    itemBuilder: (context, index) {
                      final status = statuses[index];
                      return BudgetListItem(status: status);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('오류: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 예산 항목 하나를 표시하는 위젯
class BudgetListItem extends ConsumerStatefulWidget {
  final BudgetStatus status;
  const BudgetListItem({super.key, required this.status});

  @override
  ConsumerState<BudgetListItem> createState() => _BudgetListItemState();
}

class _BudgetListItemState extends ConsumerState<BudgetListItem> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialAmount = widget.status.budgetAmount > 0
        ? NumberFormat.decimalPattern('ko_KR').format(widget.status.budgetAmount.toInt())
        : '';
    _controller = TextEditingController(text: initialAmount);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetViewModelProvider);
    final budgetRepo = ref.read(budgetRepositoryProvider);

    return ListTile(
      title: Text(widget.status.account.name),
      trailing: SizedBox(
        width: 150,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: '예산 입력',
            suffixText: '원',
          ),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.end,
          onEditingComplete: () {
            final amount = double.tryParse(_controller.text.replaceAll(',', '')) ?? 0;
            final newBudget = Budget(
              id: '', // ID는 Repository에서 생성
              accountId: widget.status.account.id,
              year: budgetState.year,
              month: budgetState.month,
              amount: amount,
            );
            budgetRepo.setBudget(newBudget);
            FocusScope.of(context).unfocus(); // 키보드 내리기
          },
        ),
      ),
    );
  }
}