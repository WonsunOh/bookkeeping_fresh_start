// lib/features/transaction/views/transaction_entry_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/enums.dart';
import '../../../core/formatters/currency_input_formatter.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../data/models/account.dart';
import '../../../data/models/journal_entry.dart';
import '../../../data/models/transaction.dart';
import '../viewmodels/account_provider.dart';
import '../viewmodels/transaction_entry_viewmodel.dart';
import '../viewmodels/transaction_viewmodel.dart';

class TransactionEntryScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;
  const TransactionEntryScreen({super.key, this.transaction});

  @override
  ConsumerState<TransactionEntryScreen> createState() =>
      _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends ConsumerState<TransactionEntryScreen> {
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initState에서는 ViewModel을 초기화하고 컨트롤러에 초기값을 설정하는 역할만 합니다.
      if (_isEditMode) {
        final accounts = ref.read(accountsStreamProvider).value;
        if (accounts != null) {
          ref
              .read(transactionEntryProvider.notifier)
              .initializeForEdit(widget.transaction!, accounts);

          // ViewModel의 초기 상태를 가져와 컨트롤러에 설정합니다.
          final initialState = ref.read(transactionEntryProvider);
          _amountController.text =
              NumberFormat.decimalPattern('ko_KR').format(initialState.amount);
          _memoController.text = initialState.description;
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- 해결책: ref.listen을 initState가 아닌 build 메서드 안으로 이동 ---
    // 이 위치에서 listen을 사용하면 Riverpod의 생명주기와 일치하여 안전합니다.
    ref.listen<TransactionEntryState>(transactionEntryProvider, (previous, next) {
      // 금액 상태가 변경되었을 때 컨트롤러의 텍스트를 업데이트
      final formattedAmount = NumberFormat.decimalPattern('ko_KR').format(next.amount);
      if (_amountController.text != formattedAmount) {
        _amountController.text = formattedAmount;
        // 커서를 맨 뒤로 이동
        _amountController.selection = TextSelection.fromPosition(
            TextPosition(offset: _amountController.text.length));
      }
      // 메모 상태가 변경되었을 때 컨트롤러의 텍스트를 업데이트
      if (_memoController.text != next.description) {
        _memoController.text = next.description;
        _memoController.selection = TextSelection.fromPosition(
            TextPosition(offset: _memoController.text.length));
      }
    });
    // -----------------------------------------------------------------

    final entryState = ref.watch(transactionEntryProvider);
    final entryViewModel = ref.read(transactionEntryProvider.notifier);

    // ... (이하 build 메서드의 나머지 코드는 이전과 동일합니다) ...
    final assetAccounts = ref.watch(accountsByTypeProvider(AccountType.asset));
    final expenseAccounts = ref.watch(accountsByTypeProvider(AccountType.expense));
    final revenueAccounts = ref.watch(accountsByTypeProvider(AccountType.revenue));
    final equityAccounts = ref.watch(accountsByTypeProvider(AccountType.equity));

    final List<Account> fromAccounts;
    final String fromAccountLabel;
    final List<Account> toAccounts;
    final String toAccountLabel;

    if (entryState.entryType == EntryScreenType.income) {
      fromAccounts = [...revenueAccounts, ...equityAccounts];
      fromAccountLabel = '어디서 (수입/자본)';
      toAccounts = assetAccounts;
      toAccountLabel = '어디로 (자산)';
    } else {
      fromAccounts = assetAccounts;
      fromAccountLabel = '어디서 (자산)';
      if (entryState.entryType == EntryScreenType.expense) {
        toAccounts = expenseAccounts;
        toAccountLabel = '무엇을 위해 (비용)';
      } else { // Transfer
        toAccounts = assetAccounts;
        toAccountLabel = '어디로 (자산)';
      }
    }

    final validFromAccount = entryState.fromAccount != null && fromAccounts.contains(entryState.fromAccount)
        ? entryState.fromAccount
        : null;
    final validToAccount = entryState.toAccount != null && toAccounts.contains(entryState.toAccount)
        ? entryState.toAccount
        : null;

    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(title: Text(_isEditMode ? '거래 수정' : '거래 기록')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<EntryScreenType>(
                segments: const [
                  ButtonSegment(value: EntryScreenType.expense, label: Text('지출')),
                  ButtonSegment(value: EntryScreenType.income, label: Text('수입')),
                  ButtonSegment(value: EntryScreenType.transfer, label: Text('이체')),
                ],
                selected: {entryState.entryType},
                onSelectionChanged: (newSelection) {
                  entryViewModel.setEntryType(newSelection.first);
                },
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('날짜'),
                trailing: TextButton(
                  child: Text('${entryState.date.year}-${entryState.date.month}-${entryState.date.day}'),
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: entryState.date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      entryViewModel.setDate(pickedDate);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Account>(
                value: validFromAccount,
                decoration: InputDecoration(labelText: fromAccountLabel, border: const OutlineInputBorder()),
                items: fromAccounts.map((account) {
                  return DropdownMenuItem(value: account, child: Text(account.name));
                }).toList(),
                onChanged: (account) {
                  if (account != null) {
                    entryViewModel.setFromAccount(account);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Account>(
                value: validToAccount,
                decoration: InputDecoration(labelText: toAccountLabel, border: const OutlineInputBorder()),
                items: toAccounts.map((account) {
                  return DropdownMenuItem(value: account, child: Text(account.name));
                }).toList(),
                onChanged: (account) {
                  if (account != null) {
                    entryViewModel.setToAccount(account);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                    labelText: '얼마나', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                onChanged: (value) {
                  final amount = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
                  entryViewModel.setAmount(amount);
                },
                textAlign: TextAlign.end,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(
                    labelText: '메모', border: OutlineInputBorder()),
                onChanged: (value) {
                  entryViewModel.setDescription(value);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  if (entryState.fromAccount == null ||
                      entryState.toAccount == null ||
                      entryState.amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('모든 항목을 올바르게 입력해주세요.')),
                    );
                    return;
                  }
                  if (entryState.fromAccount!.id == entryState.toAccount!.id) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('같은 계좌 간 거래는 할 수 없습니다.')),
                    );
                    return;
                  }
      
                  final List<JournalEntry> entries;
                  if (entryState.entryType == EntryScreenType.income) {
                    entries = [
                      JournalEntry(accountId: entryState.toAccount!.id, type: EntryType.debit, amount: entryState.amount),
                      JournalEntry(accountId: entryState.fromAccount!.id, type: EntryType.credit, amount: entryState.amount),
                    ];
                  } else {
                    entries = [
                      JournalEntry(accountId: entryState.toAccount!.id, type: EntryType.debit, amount: entryState.amount),
                      JournalEntry(accountId: entryState.fromAccount!.id, type: EntryType.credit, amount: entryState.amount),
                    ];
                  }
                  
                  if (_isEditMode) {
                    final updatedTransaction = Transaction(
                      id: widget.transaction!.id,
                      date: entryState.date,
                      description: entryState.description.isEmpty ? entryState.toAccount!.name : entryState.description,
                      entries: entries,
                    );
                    ref.read(transactionProvider.notifier).updateTransaction(updatedTransaction);
                  } else {
                    final newTransaction = Transaction(
                      id: const Uuid().v4(),
                      date: entryState.date,
                      description: entryState.description.isEmpty ? entryState.toAccount!.name : entryState.description,
                      entries: entries,
                    );
                    ref.read(transactionProvider.notifier).addTransaction(newTransaction);
                  }
                  context.go('/');
                },
                child: const Text('저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}