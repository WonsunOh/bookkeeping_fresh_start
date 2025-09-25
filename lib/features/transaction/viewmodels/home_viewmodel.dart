// lib/features/transaction/viewmodels/home_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 홈 화면의 상태를 나타내는 클래스
@immutable
class HomeState {
  final String searchQuery;
  final DateTimeRange? dateRange;

  const HomeState({
    this.searchQuery = '',
    this.dateRange,
  });

  HomeState copyWith({
    String? searchQuery,
    DateTimeRange? dateRange,
  }) {
    return HomeState(
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: dateRange ?? this.dateRange,
    );
  }
}

// HomeState를 관리하는 Notifier
class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() {
    return const HomeState();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setDateRange(DateTimeRange range) {
    state = state.copyWith(dateRange: range);
  }

  void clearFilters() {
    state = const HomeState();
  }
}

// ViewModel을 제공하는 Provider
final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(() {
  return HomeViewModel();
});