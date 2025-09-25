import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/transaction/viewmodels/transaction_viewmodel.dart';

// 검색어
final searchQueryProvider = Provider<String>((ref) => '');

// 날짜 범위 필터  
final dateRangeProvider = Provider<DateTimeRange?>((ref) => null);

// 필터링된 거래 목록
final filteredTransactionProvider = Provider<AsyncValue<List<dynamic>>>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final dateRange = ref.watch(dateRangeProvider);
  final asyncTransactions = ref.watch(transactionProvider);
  
  return asyncTransactions.whenData((transactions) {
    var result = transactions;
    
    if (searchQuery.isNotEmpty) {
      result = result.where((t) => 
        (t.description).toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }
    
    if (dateRange != null) {
      result = result.where((t) {
        final date = t.date;
        return !date.isBefore(dateRange.start) && !date.isAfter(dateRange.end);
      }).toList();
    }
    
    return result;
  });
});