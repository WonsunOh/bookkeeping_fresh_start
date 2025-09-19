// lib/features/financial_statements/views/financial_statement_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../viewmodels/financial_statement_filter_viewmodel.dart';
import '../viewmodels/financial_statement_viewmodel.dart';

class FinancialStatementScreen extends ConsumerWidget {
  const FinancialStatementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBalanceSheet = ref.watch(balanceSheetProvider);
    final asyncIncomeStatement = ref.watch(incomeStatementProvider);
    final asyncExpenseChartData = ref.watch(expenseChartDataProvider);
    // 필터 상태와 ViewModel을 가져옵니다.
    final filterState = ref.watch(financialStatementFilterProvider);
    final filterViewModel = ref.read(financialStatementFilterProvider.notifier);
    final currencyFormat = NumberFormat.decimalPattern('ko_KR');
    final dateFormat = DateFormat('yyyy.MM.dd');

    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(title: const Text('재무제표')),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${dateFormat.format(filterState.dateRange.start)} - ${dateFormat.format(filterState.dateRange.end)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final newDateRange = await showDateRangePicker(
                      context: context,
                      initialDateRange: filterState.dateRange,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (newDateRange != null) {
                      filterViewModel.setDateRange(newDateRange);
                    }
                  },
                )
              ],
            ),
            const SizedBox(height: 16),

                // 재무상태표 카드
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('재무상태표', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 16),
                        asyncBalanceSheet.when(
                          data: (bs) => Column(
                            children: [
                              _buildFinancialRow('총자산', currencyFormat.format(bs.totalAssets.toInt())),
                              _buildFinancialRow('총부채', currencyFormat.format(bs.totalLiabilities.toInt())),
                              const Divider(),
                              _buildFinancialRow('총자본', currencyFormat.format(bs.totalEquity.toInt()), isTotal: true),
                            ],
                          ),
                          loading: () => const Center(child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          )),
                          error: (err, st) => Text('오류가 발생했습니다: $err'),
                        ),
                      ],
                    ),
                  ),
                ),
             
            const SizedBox(height: 24),
            // 손익계산서 카드
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('손익계산서', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    asyncIncomeStatement.when(
                      data: (isData) => Column(
                        children: [
                          _buildFinancialRow('총수익', currencyFormat.format(isData.totalRevenue.toInt())),
                          _buildFinancialRow('총비용', currencyFormat.format(isData.totalExpenses.toInt())),
                          const Divider(),
                          _buildFinancialRow('순이익', currencyFormat.format(isData.netIncome.toInt()), isTotal: true),
                        ],
                      ),
                      loading: () => const Center(child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )),
                      error: (err, st) => Text('오류가 발생했습니다: $err'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 새로운 비용 분석 차트 카드 추가 ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('비용 분석', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    asyncExpenseChartData.when(
                      data: (chartData) {
                        if (chartData.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('분석할 지출 내역이 없습니다.'),
                            ),
                          );
                        }
                        return SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: chartData.map((data) {
                                return PieChartSectionData(
                                  value: data.value,
                                  title: '${data.percentage.toStringAsFixed(1)}%',
                                  color: _getColorFor(data.title),
                                  radius: 80,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                            ),
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, st) => Text('오류: $err'),
                    ),
                    const Divider(),
                    // 범례 (Legend)
                    asyncExpenseChartData.when(
                      data: (chartData) {
                        // 데이터가 있을 때만 범례를 보여주는 Column 위젯을 반환합니다.
                        return Column(
                          children: chartData.map((data) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    color: _getColorFor(data.title),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(data.title),
                                  const Spacer(),
                                  Text(currencyFormat.format(data.value.toInt())),
                                ],
                            ),
                          );
                        }).toList(),
                      );
                      },
                       loading: () => const SizedBox.shrink(),
                      error: (err, st) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 항목 이름에 따라 일관된 색상을 반환하는 헬퍼 함수
  Color _getColorFor(String title) {
    final hash = title.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = hash & 0x0000FF;
    return Color.fromRGBO(r, g, b, 1);
  }
  

  Widget _buildFinancialRow(String title, String value, {bool isTotal = false}) {
    final style = TextStyle(
      fontSize: 16,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: style),
          Text('$value 원', style: style),
        ],
      ),
    );
  }
}