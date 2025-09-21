// lib/features/transaction/views/transaction_list_screen.dart

// ignore_for_file: unused_result

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../viewmodels/account_provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/transaction_viewmodel.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 필터링된 거래 목록과 필터의 현재 상태를 watch합니다.
    final asyncTransactions = ref.watch(filteredTransactionsProvider);
    final homeViewModel = ref.read(homeViewModelProvider.notifier);
    final homeState = ref.watch(homeViewModelProvider);

    // 검색 필드의 텍스트를 관리하는 컨트롤러
    final searchController = TextEditingController(text: homeState.searchQuery);
    // 항상 커서를 텍스트 맨 뒤로 이동
    searchController.selection =
        TextSelection.fromPosition(TextPosition(offset: searchController.text.length));

    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('전체 거래내역'),
        ),
        body: Column(
          children: [
            // 검색 및 필터 UI
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: '거래 내용 검색...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      // 검색어가 있을 때만 '지우기' 버튼 표시
                      suffixIcon: homeState.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                homeViewModel.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      homeViewModel.setSearchQuery(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        // 버튼에 선택된 기간을 표시하여 사용자 경험 개선
                        label: Text(homeState.dateRange == null
                            ? '기간 설정'
                            : '${DateFormat('yy.MM.dd').format(homeState.dateRange!.start)} - ${DateFormat('yy.MM.dd').format(homeState.dateRange!.end)}'),
                        onPressed: () async {
                          final dateRange = await showDateRangePicker(
                            context: context,
                            initialDateRange: homeState.dateRange,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (dateRange != null) {
                            homeViewModel.setDateRange(dateRange);
                          }
                        },
                      ),
                      // 필터가 적용된 경우에만 '초기화' 버튼 표시
                      if (homeState.searchQuery.isNotEmpty || homeState.dateRange != null)
                        TextButton(
                          child: const Text('필터 초기화'),
                          onPressed: () {
                            searchController.clear();
                            homeViewModel.clearFilters();
                          },
                        )
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 거래 목록 UI
            Expanded(
              child: RefreshIndicator(
                // 화면을 아래로 당기면 이 함수가 실행됩니다.
          onRefresh: () async {
            // 1. transactionProvider를 먼저 새로고침하고 기다립니다.
            ref.refresh(transactionProvider);
            // 2. accountsStreamProvider를 새로고침하고 기다립니다.
            await ref.refresh(accountsStreamProvider.future);
          },
                child: asyncTransactions.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const Center(child: Text('해당 조건의 거래가 없습니다.'));
                    }
                    return ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        final amount = transaction.entries.first.amount;
                        final formattedAmount =
                            NumberFormat.decimalPattern('ko_KR').format(amount.toInt());
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            title: Text(transaction.description),
                            subtitle: Text(DateFormat('yyyy. MM. dd.').format(transaction.date.toLocal())),
                            trailing: Text(
                              '$formattedAmount 원',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              context.push('/transaction/${transaction.id}');
                            },
                          ),
                        );
                      },
                    );
                  },
                  error: (err, stack) => Center(child: Text('에러가 발생했습니다: $err')),
                  loading: () => const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}