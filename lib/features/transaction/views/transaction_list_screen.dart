// lib/features/transaction/views/transaction_list_screen.dart

// ignore_for_file: unused_result

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../viewmodels/account_provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/transaction_viewmodel.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String? selectedAccountId;
  double? minAmount;
  double? maxAmount;
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();
  
  // 정렬 옵션
  String sortBy = 'date';
  bool sortAscending = false;
  
  // 검색 영역 표시 여부
  bool showSearchArea = false;

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final asyncAccounts = ref.watch(accountsStreamProvider);
          
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '상세 필터',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('초기화'),
                        onPressed: () {
                          setModalState(() {
                            selectedAccountId = null;
                            minAmount = null;
                            maxAmount = null;
                            sortBy = 'date';
                            sortAscending = false;
                            _minAmountController.clear();
                            _maxAmountController.clear();
                          });
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        const Text('계정과목', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        asyncAccounts.when(
                          data: (accounts) => Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                prefixIcon: Icon(Icons.account_balance_wallet),
                              ),
                              value: selectedAccountId,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('전체 계정'),
                                ),
                                ...accounts.map((account) => DropdownMenuItem<String>(
                                      value: account.id,
                                      child: Text(account.name),
                                    )),
                              ],
                              onChanged: (value) {
                                setModalState(() => selectedAccountId = value);
                                setState(() {});
                              },
                            ),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('계정 목록 로딩 실패'),
                        ),
                        const SizedBox(height: 24),
                        
                        const Text('금액 범위', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minAmountController,
                                decoration: InputDecoration(
                                  labelText: '최소',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixText: '₩ ',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final parsed = double.tryParse(value.replaceAll(',', ''));
                                  setModalState(() => minAmount = parsed);
                                  setState(() {});
                                },
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('~', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _maxAmountController,
                                decoration: InputDecoration(
                                  labelText: '최대',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixText: '₩ ',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final parsed = double.tryParse(value.replaceAll(',', ''));
                                  setModalState(() => maxAmount = parsed);
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        const Text('정렬', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilterChip(
                              label: Text(sortAscending ? '날짜 오래된순' : '날짜 최신순'),
                              selected: sortBy == 'date',
                              onSelected: (selected) {
                                setModalState(() {
                                  if (sortBy == 'date') {
                                    sortAscending = !sortAscending;
                                  } else {
                                    sortBy = 'date';
                                    sortAscending = false;
                                  }
                                });
                                setState(() {});
                              },
                            ),
                            FilterChip(
                              label: Text(sortAscending ? '금액 낮은순' : '금액 높은순'),
                              selected: sortBy == 'amount',
                              onSelected: (selected) {
                                setModalState(() {
                                  if (sortBy == 'amount') {
                                    sortAscending = !sortAscending;
                                  } else {
                                    sortBy = 'amount';
                                    sortAscending = false;
                                  }
                                });
                                setState(() {});
                              },
                            ),
                            FilterChip(
                              label: const Text('가나다순'),
                              selected: sortBy == 'description',
                              onSelected: (selected) {
                                setModalState(() {
                                  sortBy = 'description';
                                  sortAscending = true;
                                });
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('적용', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncTransactions = ref.watch(filteredTransactionsProvider);
    final homeViewModel = ref.read(homeViewModelProvider.notifier);
    final homeState = ref.watch(homeViewModelProvider);

    final searchController = TextEditingController(text: homeState.searchQuery);
    searchController.selection =
        TextSelection.fromPosition(TextPosition(offset: searchController.text.length));

    int activeFiltersCount = 0;
    if (homeState.searchQuery.isNotEmpty) activeFiltersCount++;
    if (homeState.dateRange != null) activeFiltersCount++;
    if (selectedAccountId != null) activeFiltersCount++;
    if (minAmount != null || maxAmount != null) activeFiltersCount++;

    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('전체 거래내역'),
          actions: [
            IconButton(
              icon: Icon(showSearchArea ? Icons.search_off : Icons.search),
              tooltip: showSearchArea ? '검색 닫기' : '검색',
              onPressed: () {
                setState(() {
                  showSearchArea = !showSearchArea;
                });
              },
            ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: '상세 필터',
                  onPressed: _showFilterSheet,
                ),
                if (activeFiltersCount > 1)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '$activeFiltersCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // 검색 영역 (슬라이드 애니메이션)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: showSearchArea
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              TextField(
                                controller: searchController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: '거래 내용 검색...',
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  suffixIcon: homeState.searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            searchController.clear();
                                            homeViewModel.setSearchQuery('');
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: (value) {
                                  homeViewModel.setSearchQuery(value);
                                },
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ActionChip(
                                      avatar: const Icon(Icons.calendar_today, size: 18),
                                      label: Text(
                                        homeState.dateRange == null
                                            ? '기간 선택'
                                            : '${DateFormat('MM.dd').format(homeState.dateRange!.start)} - ${DateFormat('MM.dd').format(homeState.dateRange!.end)}',
                                      ),
                                      onPressed: () async {
                                        final dateRange = await showDateRangePicker(
                                          context: context,
                                          initialDateRange: homeState.dateRange,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                        );
                                        if (dateRange != null) {
                                          homeViewModel.setDateRange(dateRange);
                                        }
                                      },
                                      backgroundColor: homeState.dateRange != null ? Colors.blue.shade50 : null,
                                    ),
                                    const SizedBox(width: 8),
                                    FilterChip(
                                      label: const Text('오늘'),
                                      selected: _isToday(homeState.dateRange),
                                      onSelected: (selected) {
                                        if (selected) {
                                          final today = DateTime.now();
                                          final startOfDay = DateTime(today.year, today.month, today.day);
                                          homeViewModel.setDateRange(DateTimeRange(start: startOfDay, end: today));
                                        } else {
                                          homeViewModel.clearFilters();
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    FilterChip(
                                      label: const Text('이번 주'),
                                      selected: _isThisWeek(homeState.dateRange),
                                      onSelected: (selected) {
                                        if (selected) {
                                          final now = DateTime.now();
                                          final weekStart = now.subtract(Duration(days: now.weekday - 1));
                                          homeViewModel.setDateRange(DateTimeRange(
                                            start: DateTime(weekStart.year, weekStart.month, weekStart.day),
                                            end: now,
                                          ));
                                        } else {
                                          homeViewModel.clearFilters();
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    FilterChip(
                                      label: const Text('이번 달'),
                                      selected: _isThisMonth(homeState.dateRange),
                                      onSelected: (selected) {
                                        if (selected) {
                                          final now = DateTime.now();
                                          homeViewModel.setDateRange(DateTimeRange(
                                            start: DateTime(now.year, now.month, 1),
                                            end: now,
                                          ));
                                        } else {
                                          homeViewModel.clearFilters();
                                        }
                                      },
                                    ),
                                    if (activeFiltersCount > 0) ...[
                                      const SizedBox(width: 16),
                                      TextButton.icon(
                                        icon: const Icon(Icons.clear_all, size: 18),
                                        label: const Text('전체 초기화'),
                                        onPressed: () {
                                          searchController.clear();
                                          homeViewModel.clearFilters();
                                          setState(() {
                                            selectedAccountId = null;
                                            minAmount = null;
                                            maxAmount = null;
                                            sortBy = 'date';
                                            sortAscending = false;
                                            _minAmountController.clear();
                                            _maxAmountController.clear();
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            
            // 거래 목록
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.refresh(transactionProvider);
                  await ref.refresh(accountsStreamProvider.future);
                },
                child: asyncTransactions.when(
                  data: (transactions) {
                    var filteredTransactions = transactions;
                    
                    if (selectedAccountId != null) {
                      filteredTransactions = filteredTransactions.where((t) {
                        return t.entries.any((e) => e.accountId == selectedAccountId);
                      }).toList();
                    }
                    
                    if (minAmount != null || maxAmount != null) {
                      filteredTransactions = filteredTransactions.where((t) {
                        final amount = t.entries.first.amount;
                        final meetsMin = minAmount == null || amount >= minAmount!;
                        final meetsMax = maxAmount == null || amount <= maxAmount!;
                        return meetsMin && meetsMax;
                      }).toList();
                    }
                    
                    filteredTransactions.sort((a, b) {
                      int comparison;
                      switch (sortBy) {
                        case 'amount':
                          comparison = a.entries.first.amount.compareTo(b.entries.first.amount);
                          break;
                        case 'description':
                          comparison = a.description.compareTo(b.description);
                          break;
                        case 'date':
                        default:
                          comparison = a.date.compareTo(b.date);
                      }
                      return sortAscending ? comparison : -comparison;
                    });

                    if (filteredTransactions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              '해당 조건의 거래가 없습니다',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final groupedTransactions = <String, List<dynamic>>{};
                    for (var transaction in filteredTransactions) {
                      final dateKey = DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(transaction.date);
                      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
                    }
                    
                    return Column(
                      children: [
                        if (activeFiltersCount > 0)
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: Colors.blue.shade50,
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, size: 18, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  '${filteredTransactions.length}건의 거래',
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Text(
                                  '합계: ${NumberFormat.decimalPattern('ko_KR').format(filteredTransactions.fold<double>(0, (sum, t) => sum + t.entries.first.amount).toInt())}원',
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        
                        Expanded(
                          child: ListView.builder(
                            itemCount: groupedTransactions.length,
                            itemBuilder: (context, index) {
                              final dateKey = groupedTransactions.keys.elementAt(index);
                              final dayTransactions = groupedTransactions[dateKey]!;
                              final dayTotal = dayTransactions.fold<double>(
                                0, (sum, t) => sum + t.entries.first.amount,
                              );
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    color: Colors.grey.shade100,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          dateKey,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${NumberFormat.decimalPattern('ko_KR').format(dayTotal.toInt())}원',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...dayTransactions.map((transaction) {
                                    final amount = transaction.entries.first.amount;
                                    final formattedAmount =
                                        NumberFormat.decimalPattern('ko_KR').format(amount.toInt());
                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      elevation: 1,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        title: Text(
                                          transaction.description,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        trailing: Text(
                                          '$formattedAmount원',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        onTap: () => context.push('/transaction/${transaction.id}'),
                                      ),
                                    );
                                  }).toList(),
                                  const SizedBox(height: 8),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('오류: $e'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('다시 시도'),
                          onPressed: () => ref.refresh(transactionProvider),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  bool _isToday(DateTimeRange? range) {
    if (range == null) return false;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return range.start.year == startOfDay.year &&
        range.start.month == startOfDay.month &&
        range.start.day == startOfDay.day;
  }
  
  bool _isThisWeek(DateTimeRange? range) {
    if (range == null) return false;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return range.start.year == weekStartDay.year &&
        range.start.month == weekStartDay.month &&
        range.start.day == weekStartDay.day;
  }
  
  bool _isThisMonth(DateTimeRange? range) {
    if (range == null) return false;
    final now = DateTime.now();
    return range.start.year == now.year &&
        range.start.month == now.month &&
        range.start.day == 1;
  }
}