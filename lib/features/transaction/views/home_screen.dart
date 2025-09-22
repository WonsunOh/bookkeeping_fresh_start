// lib/features/transaction/views/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../../dashboard/viewmodels/account_balance_provider.dart';
import '../../dashboard/viewmodels/dashboard_viewmodel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSummary = ref.watch(dashboardSummaryProvider);
    final asyncBalances = ref.watch(accountBalanceProvider);
    final currencyFormat = NumberFormat.decimalPattern('ko_KR');

    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('회계장부 V1.0'),
          actions: [
            IconButton(
              icon: const Icon(Icons.pie_chart_outline),
              tooltip: '예산 설정',
              onPressed: () => context.push('/budget'),
            ),
            IconButton(
              icon: const Icon(Icons.repeat),
              tooltip: '반복 거래 관리',
              onPressed: () => context.push('/repeating-transactions'),
            ),
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              onPressed: () => context.push('/financial-statements'),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/accounts'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- 이번 달 요약 카드 ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: asyncSummary.when(
                  data: (summary) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('이번 달 요약', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      _buildSummaryRow('수입', summary.totalIncome, Colors.blue, currencyFormat),
                      const SizedBox(height: 8),
                      _buildSummaryRow('지출', summary.totalExpense, Colors.red, currencyFormat),
                      const Divider(height: 24),
                      _buildSummaryRow('합계', summary.netIncome, Colors.black, currencyFormat, isTotal: true),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => const Text('요약 정보를 불러올 수 없습니다.'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.bar_chart),
              label: const Text('상세 대시보드 보기'),
              onPressed: () {
                // 버튼을 누르면 '/dashboard' 경로로 이동합니다.
                context.push('/dashboard');
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 8), // 버튼 간 간격 추가
            
            // --- 전체 거래내역 보기 버튼 ---
             OutlinedButton.icon(
                icon: const Icon(Icons.list_alt),
                label: const Text('전체 거래내역 보기'),
                onPressed: (){
                  // 이전의 검색/필터 기능이 있는 화면으로 이동
                  context.push('/transactions');
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
             ),
            const SizedBox(height: 24),
            // --- 자산 현황 카드 ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: asyncBalances.when(
                  data: (balances) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('자산 현황', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      ...balances.map((b) => _buildBalanceRow(b.account.name, b.balance, currencyFormat)),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => const Text('자산 정보를 불러올 수 없습니다.'),
                ),
              ),
            ),
  
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/entry'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, double amount, Color color, NumberFormat format, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(
          '${format.format(amount.toInt())} 원',
          style: TextStyle(fontSize: 16, color: color, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }

   Widget _buildBalanceRow(String title, double amount, NumberFormat format) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text('${format.format(amount.toInt())} 원', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}