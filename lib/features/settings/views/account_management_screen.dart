// lib/features/settings/views/account_management_screen.dart (개선된 버전)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/improved_error_widget.dart';
import '../../../core/widgets/improved_async_builder.dart';
import '../../../core/widgets/improved_section_header.dart';
import '../../../core/enums.dart';
import '../../../data/models/account.dart';
import '../../transaction/viewmodels/account_provider.dart';

class AccountManagementScreen extends ConsumerStatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  ConsumerState<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends ConsumerState<AccountManagementScreen> {
  String _searchQuery = '';
  AccountType? _filterType;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsStreamProvider);

    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('계정과목 관리'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/accounts/entry'),
              tooltip: '새 계정과목 추가',
            ),
          ],
        ),
        body: Column(
          children: [
            // 검색 및 필터 UI
            _buildSearchAndFilter(),
            
            // 계정 목록
            Expanded(
              child: ImprovedAsyncBuilder(
                asyncValue: accountsAsync,
                loadingMessage: '계정과목을 불러오는 중...',
                errorMessage: '계정과목을 불러올 수 없습니다.',
                onRetry: () => ref.refresh(accountsStreamProvider),
                dataBuilder: (accounts) => _buildAccountList(context, accounts),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/accounts/entry'),
          icon: const Icon(Icons.add),
          label: const Text('계정과목 추가'),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // 검색 바
          TextField(
            decoration: const InputDecoration(
              hintText: '계정과목 이름 검색...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          
          // 필터 칩들
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('전체'),
                  selected: _filterType == null,
                  onSelected: (selected) {
                    setState(() {
                      _filterType = selected ? null : _filterType;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...AccountType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getAccountTypeDisplayName(type)),
                    selected: _filterType == type,
                    onSelected: (selected) {
                      setState(() {
                        _filterType = selected ? type : null;
                      });
                    },
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList(BuildContext context, List<Account> allAccounts) {
    // 필터링 적용
    final filteredAccounts = _applyFilters(allAccounts);
    
    if (filteredAccounts.isEmpty) {
      return EmptyDataWidget(
        message: _searchQuery.isNotEmpty || _filterType != null
            ? '검색 조건에 맞는 계정과목이 없습니다.\n다른 조건으로 검색해보세요.'
            : '아직 계정과목이 없습니다.\n첫 번째 계정과목을 추가해보세요.',
        actionText: '계정과목 추가',
        onAction: () => context.push('/accounts/entry'),
        icon: Icons.account_balance_wallet_outlined,
      );
    }

    // 계정 유형별로 그룹화
    final groupedAccounts = groupBy(filteredAccounts, (Account account) => account.type);
    final sortedTypes = AccountType.values
        .where((type) => groupedAccounts.containsKey(type))
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(accountsStreamProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: sortedTypes.length,
        itemBuilder: (context, index) {
          final type = sortedTypes[index];
          final accountsInGroup = groupedAccounts[type] ?? [];
          
          return Column(
            children: [
              ImprovedSectionHeader(
                title: _getAccountTypeDisplayName(type),
                actionText: '${accountsInGroup.length}개',
              ),
              
              // 해당 유형의 계정들
              ...accountsInGroup.map((account) => _buildAccountItem(context, account)),
              
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAccountItem(BuildContext context, Account account) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAccountTypeColor(account.type).withOpacity(0.2),
          child: Icon(
            _getAccountTypeIcon(account.type),
            color: _getAccountTypeColor(account.type),
          ),
        ),
        title: Text(
          account.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _getAccountTypeDisplayName(account.type),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/accounts/entry', extra: account),
              tooltip: '수정',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteDialog(account),
              tooltip: '삭제',
            ),
          ],
        ),
        onTap: () => context.push('/accounts/entry', extra: account),
      ),
    );
  }

  // 헬퍼 메서드들
  List<Account> _applyFilters(List<Account> accounts) {
    return accounts.where((account) {
      // 검색어 필터
      if (_searchQuery.isNotEmpty) {
        final name = account.name.toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      
      // 유형 필터
      if (_filterType != null && account.type != _filterType) {
        return false;
      }
      
      return true;
    }).toList();
  }

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

  IconData _getAccountTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.asset:
        return Icons.account_balance_wallet;
      case AccountType.liability:
        return Icons.credit_card;
      case AccountType.equity:
        return Icons.savings;
      case AccountType.revenue:
        return Icons.trending_up;
      case AccountType.expense:
        return Icons.trending_down;
    }
  }

  Color _getAccountTypeColor(AccountType type) {
    switch (type) {
      case AccountType.asset:
        return Colors.blue;
      case AccountType.liability:
        return Colors.orange;
      case AccountType.equity:
        return Colors.purple;
      case AccountType.revenue:
        return Colors.green;
      case AccountType.expense:
        return Colors.red;
    }
  }

  Future<void> _showDeleteDialog(Account account) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정과목 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\'${account.name}\' 계정과목을 정말 삭제하시겠습니까?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '삭제된 계정과목은 복구할 수 없으며, 관련된 거래 내역도 영향을 받을 수 있습니다.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        final viewModel = ref.read(accountViewModelProvider.notifier);
        await viewModel.deleteAccount(account.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('\'${account.name}\' 계정과목이 삭제되었습니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 중 오류가 발생했습니다: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}