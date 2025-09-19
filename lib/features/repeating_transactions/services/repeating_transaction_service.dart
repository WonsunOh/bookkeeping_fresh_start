// lib/features/repeating_transactions/services/repeating_transaction_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/enums.dart';
import '../../../data/models/journal_entry.dart';
import '../../../data/models/repeating_transaction.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/repeating_transaction_repository.dart';
import '../../../data/repositories/transaction_repository.dart';

class RepeatingTransactionService {
  final RepeatingTransactionRepository _repeatingRepo;
  final TransactionRepository _transactionRepo;

  RepeatingTransactionService(this._repeatingRepo, this._transactionRepo);

  // 실행되어야 할 반복 거래들을 확인하고 처리하는 메서드
  Future<void> processDueTransactions() async {
    // 모든 반복 규칙을 한 번만 가져옵니다 (Stream 대신 .first 사용)
    final rules = await _repeatingRepo.watchAll().first;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final rule in rules) {
      // 다음 예정일이 오늘이거나 과거인지 확인
      if (!rule.nextDueDate.isAfter(today)) {
        await _createTransactionFromRule(rule);
      }
    }
  }

  Future<void> _createTransactionFromRule(RepeatingTransaction rule) async {
    // 1. 규칙에 따라 새로운 거래(Transaction)를 생성합니다.
    final newTransaction = Transaction(
      id: const Uuid().v4(),
      date: rule.nextDueDate,
      description: rule.description,
      entries: _createJournalEntries(rule),
    );
    await _transactionRepo.addTransaction(newTransaction);

    // 2. 규칙의 다음 예정일을 계산합니다.
    DateTime newNextDueDate;
    switch (rule.frequency) {
      case Frequency.daily:
        newNextDueDate = rule.nextDueDate.add(const Duration(days: 1));
        break;
      case Frequency.weekly:
        newNextDueDate = rule.nextDueDate.add(const Duration(days: 7));
        break;
      case Frequency.monthly:
        newNextDueDate = DateTime(rule.nextDueDate.year, rule.nextDueDate.month + 1, rule.nextDueDate.day);
        break;
      case Frequency.yearly:
        newNextDueDate = DateTime(rule.nextDueDate.year + 1, rule.nextDueDate.month, rule.nextDueDate.day);
        break;
    }

    // 3. 수정된 규칙으로 Firestore를 업데이트합니다.
    final updatedRule = RepeatingTransaction(
        id: rule.id,
        description: rule.description,
        amount: rule.amount,
        fromAccountId: rule.fromAccountId,
        toAccountId: rule.toAccountId,
        entryType: rule.entryType,
        frequency: rule.frequency,
        nextDueDate: newNextDueDate, // 새로 계산된 예정일
        endDate: rule.endDate);
        
    await _repeatingRepo.update(updatedRule);
  }

  List<JournalEntry> _createJournalEntries(RepeatingTransaction rule) {
    if (rule.entryType == EntryScreenType.income) {
      return [
        JournalEntry(accountId: rule.toAccountId, type: EntryType.debit, amount: rule.amount),
        JournalEntry(accountId: rule.fromAccountId, type: EntryType.credit, amount: rule.amount),
      ];
    } else {
      return [
        JournalEntry(accountId: rule.toAccountId, type: EntryType.debit, amount: rule.amount),
        JournalEntry(accountId: rule.fromAccountId, type: EntryType.credit, amount: rule.amount),
      ];
    }
  }
}

// 서비스를 제공하는 Provider
final repeatingTransactionServiceProvider = Provider<RepeatingTransactionService>((ref) {
  return RepeatingTransactionService(
    ref.watch(repeatingTransactionRepositoryProvider),
    ref.watch(transactionRepositoryProvider),
  );
});

// 앱 시작 시 한 번만 실행될 로직을 위한 FutureProvider
final appStartupProvider = FutureProvider<void>((ref) async {
  await ref.read(repeatingTransactionServiceProvider).processDueTransactions();
});