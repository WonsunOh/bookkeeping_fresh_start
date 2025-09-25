// lib/features/admin/views/data_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/enums.dart';
import '../../../core/utils/data_consistency_checker.dart';
import '../../../core/utils/transaction_utils.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../data/models/account.dart';
import '../../../data/models/transaction.dart';
import '../../transaction/viewmodels/account_provider.dart';
import '../../transaction/viewmodels/transaction_viewmodel.dart';

class DataAnalysisScreen extends ConsumerStatefulWidget {
  const DataAnalysisScreen({super.key});

  @override
  ConsumerState<DataAnalysisScreen> createState() => _DataAnalysisScreenState();
}

class _DataAnalysisScreenState extends ConsumerState<DataAnalysisScreen> {
  bool _isAnalyzing = false;
  List<DataInconsistencyReport>? _inconsistencies;
  Map<String, int>? _patternStats;
  Map<EntryScreenType, int>? _typeStats;
  int _totalTransactions = 0;

  @override
  Widget build(BuildContext context) {
    final asyncTransactions = ref.watch(transactionProvider);
    final asyncAccounts = ref.watch(accountsStreamProvider);

    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('데이터 일관성 분석'),
          backgroundColor: Colors.orange,
          actions: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: '분석 시작',
              onPressed: _isAnalyzing ? null : () => _startAnalysis(asyncTransactions, asyncAccounts),
            ),
            if (_inconsistencies != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: '다시 분석',
                onPressed: _isAnalyzing ? null : () => _startAnalysis(asyncTransactions, asyncAccounts),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isAnalyzing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('데이터를 분석하고 있습니다...'),
            SizedBox(height: 8),
            Text('잠시만 기다려주세요', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_inconsistencies == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('데이터 분석을 시작하세요'),
            const SizedBox(height: 8),
            const Text('상단의 재생 버튼을 누르면 분석이 시작됩니다', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final asyncTransactions = ref.read(transactionProvider);
                final asyncAccounts = ref.read(accountsStreamProvider);
                _startAnalysis(asyncTransactions, asyncAccounts);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('분석 시작'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return _buildAnalysisResults();
  }

  void _startAnalysis(AsyncValue asyncTransactions, AsyncValue asyncAccounts) async {
    if (asyncTransactions is! AsyncData || asyncAccounts is! AsyncData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('데이터를 불러오는 중입니다. 잠시 후 다시 시도해주세요.')),
      );
      return;
    }

    setState(() { _isAnalyzing = true; });

    // UI 업데이트를 위한 짧은 지연
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final transactions = asyncTransactions.value as List<Transaction>;
      final accounts = asyncAccounts.value as List<Account>;

      // 분석 실행
      final inconsistencies = DataConsistencyChecker.checkAllTransactions(transactions, accounts);
      final patternStats = DataConsistencyChecker.generatePatternStats(transactions, accounts);
      final typeStats = DataConsistencyChecker.generateTypeStats(transactions, accounts);

      if (mounted) {
        setState(() {
          _inconsistencies = inconsistencies;
          _patternStats = patternStats;
          _typeStats = typeStats;
          _totalTransactions = transactions.length;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isAnalyzing = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('분석 중 오류 발생: $e')),
        );
      }
    }
  }

  Widget _buildAnalysisResults() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 전체 요약
          _buildSummaryCard(_totalTransactions, _inconsistencies!.length),
          
          const SizedBox(height: 16),
          
          // 거래 유형별 통계
          if (_typeStats != null)
            _buildTypeStatsCard(_typeStats!),
          
          const SizedBox(height: 16),
          
          // 계정 패턴별 통계
          if (_patternStats != null)
            _buildPatternStatsCard(_patternStats!),
          
          const SizedBox(height: 16),
          
          // 의심스러운 거래들
          if (_inconsistencies!.isNotEmpty)
            _buildInconsistenciesCard(_inconsistencies!)
          else
            _buildNoIssuesCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int totalTransactions, int inconsistentCount) {
    final percentage = totalTransactions > 0 
        ? ((totalTransactions - inconsistentCount) / totalTransactions * 100).toStringAsFixed(1)
        : '0.0';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '분석 결과 요약',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('총 거래 수: $totalTransactions개'),
                      Text('의심스러운 거래: $inconsistentCount개'),
                      Text(
                        '일관성: $percentage%',
                        style: TextStyle(
                          color: inconsistentCount == 0 ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  inconsistentCount == 0 ? Icons.check_circle : Icons.warning,
                  color: inconsistentCount == 0 ? Colors.green : Colors.orange,
                  size: 48,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeStatsCard(Map<EntryScreenType, int> typeStats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '거래 유형별 통계',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...typeStats.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getTypeIcon(entry.key),
                        size: 16,
                        color: _getTypeColor(entry.key),
                      ),
                      const SizedBox(width: 8),
                      Text(TransactionUtils.getTransactionTypeName(entry.key)),
                    ],
                  ),
                  Text('${entry.value}개', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternStatsCard(Map<String, int> patternStats) {
    final sortedPatterns = patternStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '계정 패턴별 통계',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...sortedPatterns.take(10).map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text('${entry.value}개', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
            if (sortedPatterns.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '... 외 ${sortedPatterns.length - 10}개 패턴',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInconsistenciesCard(List<DataInconsistencyReport> inconsistencies) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '의심스러운 거래 (${inconsistencies.length}개)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...inconsistencies.map((report) => _buildInconsistencyItem(report)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoIssuesCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  '데이터 일관성 검사 완료',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '모든 거래가 정상적인 패턴을 보이고 있습니다. 의심스러운 거래가 발견되지 않았습니다.',
              style: TextStyle(color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInconsistencyItem(DataInconsistencyReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.transaction.description,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                NumberFormat.decimalPattern().format(
                  report.transaction.entries.first.amount.toInt()
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${report.fromAccountName} (${_getAccountTypeKorean(report.fromAccountType)}) → ${report.toAccountName} (${_getAccountTypeKorean(report.toAccountType)})',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '예상 유형: ${TransactionUtils.getTransactionTypeName(report.expectedType)}',
            style: const TextStyle(fontSize: 12, color: Colors.blue),
          ),
          const SizedBox(height: 4),
          Text(
            report.reason,
            style: const TextStyle(fontSize: 12, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('yyyy-MM-dd').format(report.transaction.date),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              ElevatedButton(
                onPressed: () {
                  context.push('/entry', extra: report.transaction);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(60, 32),
                ),
                child: const Text(
                  '수정',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(EntryScreenType type) {
    switch (type) {
      case EntryScreenType.expense:
        return Icons.arrow_outward;
      case EntryScreenType.income:
        return Icons.arrow_downward;
      case EntryScreenType.transfer:
        return Icons.swap_horiz;
    }
  }

  Color _getTypeColor(EntryScreenType type) {
    switch (type) {
      case EntryScreenType.expense:
        return Colors.red;
      case EntryScreenType.income:
        return Colors.green;
      case EntryScreenType.transfer:
        return Colors.blue;
    }
  }

  String _getAccountTypeKorean(AccountType type) {
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
}