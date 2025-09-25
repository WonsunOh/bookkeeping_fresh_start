// lib/features/financial_statements/viewmodels/financial_statement_filter_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 재무제표 필터 상태를 나타내는 클래스
@immutable
class FinancialStatementFilterState {
  final DateTimeRange dateRange;

  const FinancialStatementFilterState({
    required this.dateRange,
  });

  // 이번 달 첫날과 마지막 날을 기본값으로 설정하는 팩토리 생성자
  factory FinancialStatementFilterState.thisMonth() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0); // 다음 달의 0일 = 이번 달의 마지막 날
    return FinancialStatementFilterState(
      dateRange: DateTimeRange(start: firstDay, end: lastDay),
    );
  }

  FinancialStatementFilterState copyWith({
    DateTimeRange? dateRange,
  }) {
    return FinancialStatementFilterState(
      dateRange: dateRange ?? this.dateRange,
    );
  }
}

// 필터 상태를 관리하는 Notifier
class FinancialStatementFilterViewModel extends Notifier<FinancialStatementFilterState> {
  @override
  FinancialStatementFilterState build() {
    return FinancialStatementFilterState.thisMonth();
  }

  void setDateRange(DateTimeRange newRange) {
    state = state.copyWith(dateRange: newRange);
  }
}

// ViewModel을 제공하는 Provider
final financialStatementFilterProvider = 
    NotifierProvider<FinancialStatementFilterViewModel, FinancialStatementFilterState>(() {
  return FinancialStatementFilterViewModel();
});