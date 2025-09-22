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
  bool _isInitialized = false; // 초기화가 한 번만 실행되도록 보장하는 플래그

  bool get _isEditMode => widget.transaction != null;

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entryState = ref.watch(transactionEntryProvider);
    final entryViewModel = ref.read(transactionEntryProvider.notifier);
    final accountsAsync = ref.watch(accountsStreamProvider);

    // 컨트롤러와 ViewModel 상태 동기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formattedAmount = NumberFormat.decimalPattern('ko_KR').format(entryState.amount);
      if (_amountController.text != formattedAmount) {
        _amountController.text = formattedAmount;
      }
      if (_memoController.text != entryState.description) {
        _memoController.text = entryState.description;
      }
    });

    return accountsAsync.when(
      loading: () => Scaffold(
          appBar: AppBar(title: Text(_isEditMode ? '거래 수정' : '거래 기록')),
          body: const Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
          appBar: AppBar(title: const Text('오류')),
          body: Center(child: Text('계정 정보를 불러오는 데 실패했습니다: $err'))),
      data: (allAccounts) {
        // --- 👇 여기가 핵심 수정 부분입니다 ---
        // 계정 목록 로딩이 성공하면, 초기화를 딱 한 번만, 그리고 안전하게 실행합니다.
        if (!_isInitialized) {
          // Future.microtask를 사용하여 build가 끝난 직후에 상태를 변경합니다.
          Future.microtask(() {
            if (_isEditMode) {
              print('=== 수정 모드 디버깅 ===');
        print('Transaction: ${widget.transaction!.description}');
        entryViewModel.initializeForEdit(widget.transaction!, allAccounts);
        
        // 초기화 후 상태 확인
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final state = ref.read(transactionEntryProvider);
          print('초기화된 상태:');
          print('- entryType: ${state.entryType}');
          print('- fromAccountType: ${state.fromAccountType}');
          print('- toAccountType: ${state.toAccountType}');
          print('- fromAccountId: ${state.fromAccountId}');
          print('- toAccountId: ${state.toAccountId}');
           });
            } else {
              entryViewModel.setEntryType(EntryScreenType.expense);
            }
          });
          _isInitialized = true;
        }

        // 디버깅 로그 추가
  print('=== DropdownButton 디버깅 ===');
  print('entryState.entryType: ${entryState.entryType}');
  print('entryState.fromAccountType: ${entryState.fromAccountType}');
  print('entryState.toAccountType: ${entryState.toAccountType}');
        // ------------------------------------

        final List<AccountType> fromAccountTypes;
        final String fromAccountLabel;
        final List<AccountType> toAccountTypes;
        final String toAccountLabel;

        switch (entryState.entryType) {
          case EntryScreenType.income:
            fromAccountTypes = [AccountType.revenue, AccountType.equity, AccountType.liability];
            fromAccountLabel = '어디서 (수익/자본/부채)';
            toAccountTypes = [AccountType.asset, AccountType.liability];
            toAccountLabel = '어디로 (자산/부채)';
            break;
          case EntryScreenType.expense:
            fromAccountTypes = [AccountType.asset, AccountType.liability];
            fromAccountLabel = '어디서 (자산/부채)';
            toAccountTypes = [AccountType.expense, AccountType.equity];
            toAccountLabel = '무엇을 위해 (비용/자본)';
            break;
          case EntryScreenType.transfer:
            fromAccountTypes = [AccountType.asset];
            fromAccountLabel = '어디서 (자산)';
            toAccountTypes = [AccountType.asset, AccountType.liability];
            toAccountLabel = '어디로 (자산/부채)';
            break;
        }

        final fromAccounts = entryState.fromAccountType == null
            ? <Account>[]
            : allAccounts.where((a) => a.type == entryState.fromAccountType).toList();
        final toAccounts = entryState.toAccountType == null
            ? <Account>[]
            : allAccounts.where((a) => a.type == entryState.toAccountType).toList();

        final validFromAccount = entryState.fromAccountId != null && fromAccounts.any((a) => a.id == entryState.fromAccountId)
            ? fromAccounts.firstWhere((a) => a.id == entryState.fromAccountId) : null;
            
        final validToAccount = entryState.toAccountId != null && toAccounts.any((a) => a.id == entryState.toAccountId)
            ? toAccounts.firstWhere((a) => a.id == entryState.toAccountId) : null;


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
                      child: Text(DateFormat('yyyy.MM.dd').format(entryState.date)),
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: entryState.date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) entryViewModel.setDate(pickedDate);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(fromAccountLabel, style: Theme.of(context).textTheme.titleSmall),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<AccountType>(
                          value: fromAccountTypes.contains(entryState.fromAccountType) 
    ? entryState.fromAccountType 
    : null, // value가 items에 없으면 null로 설정
                          hint: const Text('유형'),
                          items: fromAccountTypes.toSet().map((type) => 
    DropdownMenuItem(value: type, child: Text(_getAccountTypeLabel(type)))
  ).toList(),
                          onChanged: (type) {
                            if (type != null) entryViewModel.setFromAccountType(type);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<Account>(
                          value: validFromAccount,
                          hint: const Text('계정과목'),
                          items: fromAccounts.map((account) => DropdownMenuItem(value: account, child: Text(account.name))).toList(),
                          onChanged: (account) {
                            entryViewModel.setFromAccount(account);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(toAccountLabel, style: Theme.of(context).textTheme.titleSmall),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<AccountType>(
                          value: toAccountTypes.contains(entryState.toAccountType) 
    ? entryState.toAccountType 
    : null, // value가 items에 없으면 null로 설정
                          hint: const Text('유형'),
                          items: toAccountTypes.toSet().map((type) => 
    DropdownMenuItem(value: type, child: Text(_getAccountTypeLabel(type)))
  ).toList(),
                          onChanged: (type) {
                            if (type != null) entryViewModel.setToAccountType(type);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<Account>(
                          value: validToAccount,
                          hint: const Text('계정과목'),
                          items: toAccounts.map((account) => DropdownMenuItem(value: account, child: Text(account.name))).toList(),
                          onChanged: (account) {
                            entryViewModel.setToAccount(account);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: '얼마나', border: OutlineInputBorder()),
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
                    decoration: const InputDecoration(labelText: '메모', border: OutlineInputBorder()),
                    onChanged: (value) {
                      entryViewModel.setDescription(value);
                    },
                  ),
                  const SizedBox(height: 32),
                  
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        final currentState = ref.read(transactionEntryProvider);
                        if (currentState.fromAccountId == null ||
                            currentState.toAccountId == null ||
                            currentState.amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('모든 항목을 올바르게 입력해주세요.')),
                          );
                          return;
                        }
                        if (currentState.fromAccountId == currentState.toAccountId) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('같은 계좌 간 거래는 할 수 없습니다.')),
                          );
                          return;
                        }
final toAccountName = allAccounts.firstWhere((a) => a.id == currentState.toAccountId).name;
                  
                  final List<JournalEntry> entries = [
                    JournalEntry(accountId: currentState.toAccountId!, type: EntryType.debit, amount: currentState.amount),
                    JournalEntry(accountId: currentState.fromAccountId!, type: EntryType.credit, amount: currentState.amount),
                  ];
                  
                  // 1. 먼저 현재 화면에서 안전하게 벗어납니다.
                  context.go('/');

                  // 2. 화면을 벗어난 후에 데이터 저장을 요청합니다.
                  // Future.microtask는 현재 작업이 끝난 직후에 코드를 실행하도록 예약하여
                  // 실시간 업데이트와 화면 전환이 충돌하는 것을 방지합니다.
                  Future.microtask(() {
                    if (_isEditMode) {
                      final updatedTransaction = Transaction(
                        id: widget.transaction!.id,
                        date: currentState.date,
                        description: currentState.description.isEmpty ? toAccountName : currentState.description,
                        entries: entries,
                      );
                      ref.read(transactionProvider.notifier).updateTransaction(updatedTransaction);
                    } else {
                      final newTransaction = Transaction(
                        id: const Uuid().v4(),
                        date: currentState.date,
                        description: currentState.description.isEmpty ? toAccountName : currentState.description,
                        entries: entries,
                      );
                      ref.read(transactionProvider.notifier).addTransaction(newTransaction);
                    }
                  });
                },
                      child: const Text('저장하기'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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