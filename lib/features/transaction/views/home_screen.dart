// lib/features/transaction/views/home_screen.dart (완성된 버전)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/improved_error_widget.dart';
import '../../../core/enums.dart';
import '../../../data/models/journal_entry.dart';
import '../../dashboard/viewmodels/account_balance_provider.dart';
import '../../dashboard/viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/account_provider.dart';
import '../viewmodels/transaction_viewmodel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSummary = ref.watch(dashboardSummaryProvider);
    final asyncBalances = ref.watch(accountBalanceProvider);
    final asyncTransactions = ref.watch(transactionProvider);
    final currencyFormat = NumberFormat.decimalPattern('ko_KR');

    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('회계장부 V1.0'),
              Text(
                DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.pie_chart_outline),
              tooltip: '예산 관리',
              onPressed: () => context.push('/budget'),
            ),
            IconButton(
              icon: const Icon(Icons.repeat),
              tooltip: '반복 거래',
              onPressed: () => context.push('/repeating-transactions'),
            ),
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              tooltip: '재무제표',
              onPressed: () => context.push('/financial-statements'),
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'accounts',
                  child: ListTile(
                    leading: Icon(Icons.account_balance_wallet),
                    title: Text('계정과목 관리'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('설정'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'accounts':
                    context.push('/accounts');
                    break;
                  case 'settings':
                    context.push('/settings');
                    break;
                }
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.refresh(transactionProvider);
            ref.refresh(accountsStreamProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 요약 정보 카드 (실제 데이터 표시)
                _buildSimpleSummaryCard(context, currencyFormat, ref),
                const SizedBox(height: 24),

                // 계좌 잔액 현황
                _buildAccountBalances(context, asyncBalances, currencyFormat, ref),
                const SizedBox(height: 24),

                // 최근 거래 내역
                _buildRecentTransactions(context, asyncTransactions, currencyFormat, ref),
                const SizedBox(height: 24),

                // 빠른 액션 버튼들
                _buildQuickActions(context),
                
                // 하단 여백
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/entry'),
          icon: const Icon(Icons.add),
          label: const Text('거래 추가'),
          tooltip: '새 거래 기록',
        ),
      ),
    );
  }

  // ✅ 완성된 요약 카드 - 실제 데이터 표시
  Widget _buildSimpleSummaryCard(BuildContext context, NumberFormat currencyFormat, WidgetRef ref) {
    final asyncSummary = ref.watch(dashboardSummaryProvider);
    final asyncBalances = ref.watch(accountBalanceProvider);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 실제 데이터를 표시하는 Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 총 자산 표시
                asyncBalances.when(
                  data: (balances) {
                    final total = balances.fold<double>(0.0, (sum, balance) => sum + balance.balance);
                    return _buildSummaryItem(
                      context,
                      '총 자산',
                      '${currencyFormat.format(total)}원',
                      Icons.account_balance_wallet,
                      Theme.of(context).colorScheme.primary,
                    );
                  },
                  loading: () => _buildSummaryItem(
                    context,
                    '총 자산',
                    '계산 중...',
                    Icons.account_balance_wallet,
                    Theme.of(context).colorScheme.primary,
                  ),
                  error: (_, __) => _buildSummaryItem(
                    context,
                    '총 자산',
                    '오류 발생',
                    Icons.account_balance_wallet,
                    Colors.grey,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                // 이번 달 지출 표시
                asyncSummary.when(
                  data: (summary) => _buildSummaryItem(
                    context,
                    '이번 달 지출',
                    '${currencyFormat.format(summary.totalExpense)}원',
                    Icons.trending_down,
                    Colors.red,
                  ),
                  loading: () => _buildSummaryItem(
                    context,
                    '이번 달 지출',
                    '계산 중...',
                    Icons.trending_down,
                    Colors.red,
                  ),
                  error: (_, __) => _buildSummaryItem(
                    context,
                    '이번 달 지출',
                    '오류 발생',
                    Icons.trending_down,
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountBalances(
    BuildContext context,
    AsyncValue<dynamic> asyncBalances,
    NumberFormat currencyFormat,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '계좌 잔액',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/accounts'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('계좌 관리'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        asyncBalances.when(
          data: (balances) {
            if (balances == null || balances.isEmpty) {
              return const EmptyDataWidget(
                message: '계좌가 없습니다.\n계좌를 추가해보세요.',
                actionText: '계좌 추가',
                icon: Icons.account_balance_wallet_outlined,
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (balances.length as int).clamp(0, 3), // 최대 3개만 표시
              itemBuilder: (context, index) {
                final balance = balances[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: Text(balance.account.name),
                    subtitle: Text('${_getAccountTypeDisplayName(balance.account.type)} 계좌'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${currencyFormat.format(balance.balance)}원',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: balance.balance >= 0 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const ImprovedLoadingWidget(message: '계좌 정보를 불러오는 중...'),
          error: (error, stack) => ImprovedErrorWidget(
            message: '계좌 정보를 불러올 수 없습니다.',
            onRetry: () => ref.refresh(accountBalanceProvider),
          ),
        ),
      ],
    );
  }

  // AccountType을 한글로 변환하는 헬퍼 메서드
  String _getAccountTypeDisplayName(AccountType type) {
    switch (type) {
      case AccountType.asset:
        return '자산';
      case AccountType.liability:
        return '부채';
      case AccountType.equity:
        return '자본';
      case AccountType.revenue:
        return '수익';
      case AccountType.expense:
        return '비용';
    }
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    AsyncValue<List<dynamic>> asyncTransactions,
    NumberFormat currencyFormat,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '최근 거래',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/transactions'),
              icon: const Icon(Icons.list, size: 16),
              label: const Text('전체 보기'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        asyncTransactions.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return const EmptyDataWidget(
                message: '아직 거래 내역이 없습니다.\n첫 거래를 기록해보세요.',
                actionText: '거래 추가',
                icon: Icons.receipt_long_outlined,
              );
            }

            final recentTransactions = transactions.take(5).toList();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentTransactions.length,
              itemBuilder: (context, index) {
                final transaction = recentTransactions[index];
                
                // 안전한 엔트리 찾기
                JournalEntry? debitEntry;
                try {
                  debitEntry = transaction.entries?.firstWhere(
                    (e) => e.type == EntryType.debit,
                  );
                } catch (e) {
                  debitEntry = transaction.entries?.isNotEmpty == true 
                      ? transaction.entries!.first 
                      : null;
                }
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                      child: Icon(
                        Icons.receipt,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                    ),
                    title: Text(
                      transaction.description ?? '거래',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      DateFormat('MM월 dd일 (E)', 'ko_KR').format(
                        transaction.date ?? DateTime.now(),
                      ),
                    ),
                    trailing: Text(
                      '${currencyFormat.format(debitEntry?.amount ?? 0)}원',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onTap: () => context.push('/transaction/${transaction.id}'),
                  ),
                );
              },
            );
          },
          loading: () => const ImprovedLoadingWidget(message: '거래 내역을 불러오는 중...'),
          error: (error, stack) => ImprovedErrorWidget(
            message: '거래 내역을 불러올 수 없습니다.',
            onRetry: () => ref.refresh(transactionProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠른 작업',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildQuickActionCard(
              context,
              '지출 기록',
              Icons.trending_down,
              Colors.red,
              () => context.push('/entry'),
            ),
            _buildQuickActionCard(
              context,
              '수입 기록',
              Icons.trending_up,
              Colors.green,
              () => context.push('/entry'),
            ),
            _buildQuickActionCard(
              context,
              '계좌 이체',
              Icons.swap_horiz,
              Colors.blue,
              () => context.push('/entry'),
            ),
            _buildQuickActionCard(
              context,
              '예산 확인',
              Icons.pie_chart,
              Colors.orange,
              () => context.push('/budget'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// EmptyDataWidget와 ImprovedLoadingWidget 임시 구현
class EmptyDataWidget extends StatelessWidget {
  final String message;
  final String? actionText;
  final IconData? icon;

  const EmptyDataWidget({
    super.key,
    required this.message,
    this.actionText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon!,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ImprovedLoadingWidget extends StatelessWidget {
  final String message;

  const ImprovedLoadingWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}