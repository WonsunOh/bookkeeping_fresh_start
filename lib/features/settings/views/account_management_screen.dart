// lib/features/settings/views/account_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart'; // groupBy를 사용하기 위해 추가

import '../../../core/enums.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../data/models/account.dart';
import '../../transaction/viewmodels/account_provider.dart';
import '../widgets/add_account_dialog.dart';

class AccountManagementScreen extends ConsumerWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // DB의 계정과목 목록을 실시간으로 watch합니다.
    final asyncAccounts = ref.watch(accountsStreamProvider);

    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
          title: const Text('계정과목 관리'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                context: context,
                // barrierDismissible: false, // 바깥 영역을 탭해도 닫히지 않게 하려면
                builder: (context) => const AddEditAccountDialog(),
              );
              },
            ),
          ],
        ),
        body: asyncAccounts.when(
          data: (accounts) {
            if (accounts.isEmpty) {
              return const Center(child: Text('계정과목이 없습니다. 우측 상단 + 버튼으로 추가하세요.'));
            }
            // 계정 유형(자산, 비용 등)에 따라 그룹화합니다.
            final groupedAccounts = groupBy(accounts, (Account account) => account.type);
      
            return ListView(
              children: AccountType.values.map((type) {
                final accountsInGroup = groupedAccounts[type] ?? [];
                if (accountsInGroup.isEmpty) return const SizedBox.shrink();
      
                return ExpansionTile(
                  title: Text(_getAccountTypeLabel(type), style: const TextStyle(fontWeight: FontWeight.bold)),
                  initiallyExpanded: true,
                  children: accountsInGroup.map((account) {
                    return ListTile(
                      title: Text(account.name),
                      trailing: const Icon(Icons.edit),
                      onTap: () {
                        // 계정 수정 화면으로 이동 (id 전달)
                        context.go('/accounts/edit/${account.id}');
                      },
                    );
                  }).toList(),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('오류가 발생했습니다: $err')),
        ),
      ),
    );
  }

  String _getAccountTypeLabel(AccountType type) {
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