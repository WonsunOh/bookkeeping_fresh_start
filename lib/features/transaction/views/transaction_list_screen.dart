// lib/features/transaction/views/transaction_list_screen.dart (개선된 버전)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/improved_error_widget.dart';
import '../../../core/widgets/improved_list_item.dart';
import '../../../core/widgets/improved_section_header.dart';
import '../../../core/widgets/korean_currency_formatter.dart';
import '../../../core/widgets/improved_async_builder.dart';
import '../../../core/enums.dart';
import '../../../data/models/journal_entry.dart';
import '../viewmodels/transaction_viewmodel.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final asyncTransactions = ref.watch(transactionProvider);

    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('거래 내역'),
          actions: [
            IconButton(
              icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              tooltip: '필터',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/entry'),
              tooltip: '새 거래 추가',
            ),
          ],
        ),
        body: Column(
          children: [
            // 검색 및 필터 UI
            if (_showFilters) _buildFilterSection(context),
            
            // 거래 목록
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.refresh(transactionProvider);
                },
                child: ImprovedAsyncBuilder(
                  asyncValue: asyncTransactions,
                  loadingMessage: '거래 내역을 불러오는 중...',
                  errorMessage: '거래 내역을 불러오는 중 오류가 발생했습니다.',
                  onRetry: () => ref.refresh(transactionProvider),
                  dataBuilder: (transactions) => _buildTransactionList(context, transactions),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/entry'),
          tooltip: '새 거래 추가',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
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
              hintText: '거래 내용 검색...',
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
          
          // 날짜 필터
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectStartDate(context),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _startDate != null 
                        ? KoreanDateFormatter.formatMonthDay(_startDate!)
                        : '시작일',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('~'),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectEndDate(context),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _endDate != null 
                        ? KoreanDateFormatter.formatMonthDay(_endDate!)
                        : '종료일',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                tooltip: '필터 초기화',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context, List<dynamic> allTransactions) {
    // 필터링 적용
    final filteredTransactions = _applyFilters(allTransactions);
    
    if (filteredTransactions.isEmpty) {
      return EmptyDataWidget(
        message: _searchQuery.isNotEmpty || _startDate != null || _endDate != null
            ? '검색 조건에 맞는 거래가 없습니다.\n다른 조건으로 검색해보세요.'
            : '아직 거래 내역이 없습니다.\n첫 거래를 기록해보세요.',
        actionText: '거래 추가',
        onAction: () => context.push('/entry'),
        icon: Icons.receipt_long_outlined,
      );
    }

    // 날짜별로 그룹화
    final groupedTransactions = _groupTransactionsByDate(filteredTransactions);
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final group = groupedTransactions[index];
        return Column(
          children: [
            // 날짜 헤더
            ImprovedSectionHeader(
              title: _formatGroupDate(group.date),
              actionText: '총 ${group.transactions.length}건',
            ),
            
            // 해당 날짜의 거래들
            ...group.transactions.map((transaction) => 
              _buildTransactionItem(context, transaction)
            ),
            
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(BuildContext context, dynamic transaction) {
    // 안전한 엔트리 찾기
    JournalEntry? primaryEntry;
    try {
      primaryEntry = transaction.entries?.firstWhere(
        (e) => e.type == EntryType.debit,
      );
    } catch (e) {
      primaryEntry = transaction.entries?.isNotEmpty == true 
          ? transaction.entries!.first 
          : null;
    }

    final amount = primaryEntry?.amount ?? 0;
    final (formattedAmount, isPositive) = KoreanCurrencyFormatter.formatWithSign(amount);
    
    return ImprovedListItem(
      title: transaction.description ?? '거래',
      subtitle: KoreanDateFormatter.formatRelative(transaction.date ?? DateTime.now()),
      trailing: formattedAmount,
      trailingColor: isPositive 
          ? Theme.of(context).colorScheme.primary 
          : Theme.of(context).colorScheme.error,
      leadingIcon: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        child: Icon(
          _getTransactionIcon(transaction),
          color: Theme.of(context).colorScheme.onTertiaryContainer,
          size: 20,
        ),
      ),
      onTap: () => context.push('/transaction/${transaction.id}'),
    );
  }

  // 헬퍼 메서드들
  List<dynamic> _applyFilters(List<dynamic> transactions) {
    return transactions.where((transaction) {
      // 검색어 필터
      if (_searchQuery.isNotEmpty) {
        final description = transaction.description?.toLowerCase() ?? '';
        if (!description.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      
      // 날짜 필터
      final transactionDate = transaction.date ?? DateTime.now();
      if (_startDate != null && transactionDate.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && transactionDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
        return false;
      }
      
      return true;
    }).toList();
  }

  List<TransactionGroup> _groupTransactionsByDate(List<dynamic> transactions) {
    final Map<String, List<dynamic>> groups = {};
    
    for (final transaction in transactions) {
      final date = transaction.date ?? DateTime.now();
      final dateKey = '${date.year}-${date.month}-${date.day}';
      
      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(transaction);
    }
    
    // 날짜순 정렬 (최신순)
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return sortedKeys.map((key) {
      final transactions = groups[key]!;
      final date = transactions.first.date ?? DateTime.now();
      return TransactionGroup(date: date, transactions: transactions);
    }).toList();
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);
    
    if (transactionDate == today) {
      return '오늘';
    } else if (transactionDate == today.subtract(const Duration(days: 1))) {
      return '어제';
    } else {
      return KoreanDateFormatter.formatDateWithDay(date);
    }
  }

  IconData _getTransactionIcon(dynamic transaction) {
    // 거래 유형에 따른 아이콘 반환
    try {
      final debitEntry = transaction.entries?.firstWhere(
        (e) => e.type == EntryType.debit,
      );
      
      if (debitEntry != null) {
        // 여기서 계정 유형에 따라 아이콘 결정
        // 임시로 기본 아이콘 반환
        return Icons.receipt;
      }
    } catch (e) {
      // 에러 시 기본 아이콘
    }
    
    return Icons.receipt_long;
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
      helpText: '시작일 선택',
      cancelText: '취소',
      confirmText: '확인',
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
      helpText: '종료일 선택',
      cancelText: '취소',
      confirmText: '확인',
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _startDate = null;
      _endDate = null;
    });
  }
}

// 거래 그룹 모델
class TransactionGroup {
  final DateTime date;
  final List<dynamic> transactions;

  TransactionGroup({
    required this.date,
    required this.transactions,
  });
}