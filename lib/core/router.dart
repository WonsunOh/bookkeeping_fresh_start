// lib/core/router.dart

import 'package:go_router/go_router.dart';
import '../data/models/repeating_transaction.dart';
import '../data/models/transaction.dart';
import '../features/budget/views/budget_screen.dart';
import '../features/financial_statements/views/financial_statement_screen.dart';
import '../features/repeating_transactions/views/add_edit_repeating_transaction_screen.dart';
import '../features/repeating_transactions/views/repeating_transaction_list_screen.dart';
import '../features/settings/views/account_management_screen.dart';
import '../features/transaction/views/home_screen.dart';
import '../features/transaction/views/transaction_detail_screen.dart';
import '../features/transaction/views/transaction_entry_screen.dart';
import '../features/transaction/views/transaction_list_screen.dart';
// ... 다른 import들

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/transactions',
      name: 'transactions',
      builder: (context, state) => const TransactionListScreen(),
    ),
    GoRoute(
        path: '/transaction/:id', // 👈 경로 매개변수 ':id' 사용
        name: 'transactionId',
        builder: (context, state) {
          // 경로에서 'id' 값을 추출합니다.
          final transactionId = state.pathParameters['id']!;
          // 추출한 id를 TransactionDetailScreen에 전달합니다.
          return TransactionDetailScreen(transactionId: transactionId);
        },
      ),
    GoRoute(
      path: '/entry',
      name: 'entry',
      builder: (context, state) {
        // --- 해결책: state.extra에서 transaction 객체를 가져옵니다. ---
        // context.go('/entry', extra: transaction)으로 전달된 객체입니다.
        // 추가 모드일 때는 null이 될 수 있으므로 nullable(?)로 받습니다.
        final transaction = state.extra as Transaction?;
        // --------------------------------------------------------
        return TransactionEntryScreen(transaction: transaction);
      },
    ),
    GoRoute(
      path: '/financial-statements',
      name: 'financialStatements',
      builder: (context, state) => const FinancialStatementScreen(),
    ),
    // 계정과목 관리 화면 라우트 추가
    GoRoute(
      path: '/accounts',
      name: 'accounts',
      builder: (context, state) => const AccountManagementScreen(),
    ),
   
    GoRoute(
      path: '/repeating-transactions',
      name: 'repeatingTransactions',
      builder: (context, state) => const RepeatingTransactionListScreen(),
    ),
    GoRoute(
      path: '/repeating-transactions/entry',
      name: 'repeatingTransactionEntry',
      builder: (context, state) {
        final rule = state.extra as RepeatingTransaction?;
        return AddEditRepeatingTransactionScreen(rule: rule);
      },
    ),
     GoRoute(
      path: '/budget',
      name: 'budget',
      builder: (context, state) => const BudgetScreen(),
    ),
  ],
);