// lib/features/admin/views/database_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../../transaction/viewmodels/account_provider.dart';
import '../../transaction/viewmodels/transaction_viewmodel.dart';

class DatabaseInfoScreen extends ConsumerWidget {
  const DatabaseInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTransactions = ref.watch(transactionProvider);
    final asyncAccounts = ref.watch(accountsStreamProvider);

    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('데이터베이스 정보'),
          backgroundColor: Colors.purple,
        ),
        body: switch ((asyncTransactions, asyncAccounts)) {
          (AsyncData(value: final transactions), AsyncData(value: final accounts)) =>
            _buildInfoView(context, transactions.length, accounts.length),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _buildInfoView(BuildContext context, int transactionCount, int accountCount) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInfoCard(
          title: '기본 통계',
          children: [
            _buildInfoRow('총 거래 수', '$transactionCount개'),
            _buildInfoRow('총 계정 수', '$accountCount개'),
            _buildInfoRow('데이터베이스 상태', '정상'),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: '빠른 작업',
          children: [
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('상세 데이터 분석'),
              subtitle: const Text('거래 패턴 및 오류 분석'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _DataAnalysisLoadingScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// 데이터 분석 화면으로의 로딩 화면
class _DataAnalysisLoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('데이터 분석 준비 중')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('데이터를 분석하고 있습니다...'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/admin/data-analysis');
              },
              child: const Text('분석 화면으로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}