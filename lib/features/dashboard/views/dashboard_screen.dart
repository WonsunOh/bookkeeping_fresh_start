// lib/features/dashboard/views/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/enums.dart';
import '../viewmodels/dashboard_viewmodel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTransactionsAsync = ref.watch(recentTransactionsProvider);
    final barChartAsyncData = ref.watch(monthlyBarChartProvider);
    final thisMonthSummaryAsync = ref.watch(thisMonthSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('대시보드'),
      ),
      body:  Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 상단 고정 영역 ---
            const SizedBox(height: 16),
            const Text("이번 달 요약", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            thisMonthSummaryAsync.when(
              data: (summary) => Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: '총수입',
                      // 이제 AsyncValue가 아닌 double 값을 직접 전달합니다.
                      amount: summary['revenue'] ?? 0,
                      color: Colors.green.shade100,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: '총지출',
                      amount: summary['expense'] ?? 0,
                      color: Colors.red.shade100,
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Center(child: Text('요약 정보 로딩 실패')),
            ),
            const SizedBox(height: 24),
        
            // 2. 월별 수입/지출 차트
            const Text("월별 수입/지출", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: barChartAsyncData.when(
                    data: (chartData) {
                      return BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceBetween,
                          barGroups: chartData.barGroups, // data.barGroups 사용
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= chartData.titles.length) {
                                    return const SizedBox.shrink();
                                  }
                                  // data.titles 사용
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(chartData.titles[index], style: const TextStyle(fontSize: 12)),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => const Center(child: Text("차트 로딩 실패")),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
        
            // 3. 최근 거래 내역
            const Text("최근 거래 내역", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: recentTransactionsAsync.when(
                data: (transactionInfos) { // 이제 'RecentTransactionInfo' 리스트를 받습니다.
                  if (transactionInfos.isEmpty) {
                    return const Center(
                      child: Padding(padding: EdgeInsets.all(20.0), child: Text('최근 거래 내역이 없습니다.')),
                    );
                  }
                  return ListView.builder(
                    itemCount: transactionInfos.length,
                    itemBuilder: (context, index) {
                      final info = transactionInfos[index];
                      final transaction = info.transaction;
                      final amount = transaction.entries.first.amount;
              
                      final IconData iconData;
                      final Color color;
                      final String prefix;
              
                      // ⭐ [핵심 수정] 이제 EntryScreenType을 직접 사용합니다.
                      switch (info.type) {
                        case EntryScreenType.expense:
                          iconData = Icons.arrow_circle_down_outlined;
                          color = Colors.redAccent;
                          prefix = '-';
                          break;
                        case EntryScreenType.income:
                          iconData = Icons.arrow_circle_up_outlined;
                          color = Colors.green;
                          prefix = '+';
                          break;
                        case EntryScreenType.transfer:
                          iconData = Icons.swap_horiz_rounded;
                          color = Colors.grey.shade700;
                          prefix = '';
                          break;
                      }
              
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(iconData, color: color, size: 30),
                          title: Text(transaction.description),
                          subtitle: Text(DateFormat('M월 d일').format(transaction.date)),
                          trailing: Text(
                            '$prefix${NumberFormat.decimalPattern().format(amount)}원',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const Center(child: Text("거래 내역 로딩 실패")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// 요약 정보를 보여주는 재사용 가능한 카드 위젯
class SummaryCard extends StatelessWidget {
  final String title;
 final double amount;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),

            // 금액을 표시하는 Text 위젯을 SizedBox와 FittedBox로 감싸줍니다.
            SizedBox(
              height: 24, // Text 위젯의 최대 높이를 고정합니다.
              child: FittedBox(
                fit: BoxFit.contain, // 공간에 맞게 내용(글자)을 축소합니다.
                alignment: Alignment.centerLeft, // 왼쪽 정렬
                child: Text(
                  '${NumberFormat.decimalPattern().format(amount)}원',
                  // 고정된 fontSize를 제거하고 스타일만 지정합니다.
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}