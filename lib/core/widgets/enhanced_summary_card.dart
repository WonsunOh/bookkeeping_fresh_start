import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class EnhancedSummaryCard extends StatelessWidget {
  final String title;
  final double currentValue;
  final double previousValue;
  final List<double> chartData;

  const EnhancedSummaryCard({
    super.key,
    required this.title,
    required this.currentValue,
    required this.previousValue,
    required this.chartData,
  });

  @override
  Widget build(BuildContext context) {
    final changePercent = previousValue != 0 
        ? ((currentValue - previousValue) / previousValue * 100)
        : 0.0;
        
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${NumberFormat.decimalPattern('ko_KR').format(currentValue)}원',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Row(
              children: [
                Icon(
                  changePercent >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: changePercent >= 0 ? Colors.green : Colors.red,
                  size: 16,
                ),
                Text(
                  '${changePercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: changePercent >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((e) => 
                        FlSpot(e.key.toDouble(), e.value)
                      ).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
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
}