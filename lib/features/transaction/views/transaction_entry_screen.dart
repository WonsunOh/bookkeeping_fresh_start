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
  bool _isLoading = false;

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    // 위젯이 빌드된 후 딱 한 번만 실행되어 초기 상태를 설정합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(transactionEntryProvider.notifier);
      if (_isEditMode) {
        // '수정' 모드일 경우, 전달받은 거래 정보로 ViewModel 상태를 초기화합니다.
        final accounts = ref.read(accountsStreamProvider).value;
        if (accounts != null) {
          notifier.initializeForEdit(widget.transaction!, accounts);
        }
      } else {
        // '추가' 모드일 경우, ViewModel 상태를 기본 '지출' 유형으로 초기화합니다.
        notifier.setEntryType(EntryScreenType.expense);
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
    // ViewModel의 상태가 변경되면 이 화면은 자동으로 다시 그려집니다.
    final entryState = ref.watch(transactionEntryProvider);
    final entryViewModel = ref.read(transactionEntryProvider.notifier);

    // 컨트롤러와 ViewModel 상태를 동기화합니다 (ViewModel -> UI 단방향).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formattedAmount = NumberFormat.decimalPattern('ko_KR').format(entryState.amount);
      if (_amountController.text != formattedAmount) {
        _amountController.text = formattedAmount;
        _amountController.selection = TextSelection.fromPosition(TextPosition(offset: _amountController.text.length));
      }
      if (_memoController.text != entryState.description) {
        _memoController.text = entryState.description;
        _memoController.selection = TextSelection.fromPosition(TextPosition(offset: _memoController.text.length));
      }
    });

    final allAccounts = ref.watch(accountsStreamProvider).value ?? [];
    
    // 거래 유형에 따라 드롭다운에 표시될 계정 유형 목록과 라벨을 결정합니다.
    final List<AccountType> fromAccountTypes;
    final String fromAccountLabel;
    final List<AccountType> toAccountTypes;
    final String toAccountLabel;

    switch (entryState.entryType) {
      case EntryScreenType.income:
        fromAccountTypes = [AccountType.revenue, AccountType.equity, AccountType.liability];
        fromAccountLabel = '어디서 (수입/자본/부채)';
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

    // ViewModel에 저장된 '선택된 계정 유형'에 따라 실제 계정 목록을 필터링합니다.
    final fromAccounts = entryState.fromAccountType == null 
        ? <Account>[] 
        : allAccounts.where((a) => a.type == entryState.fromAccountType).toList();
    final toAccounts = entryState.toAccountType == null
        ? <Account>[]
        : allAccounts.where((a) => a.type == entryState.toAccountType).toList();

    // 충돌 방지를 위한 유효성 검사 로직
    final validFromAccountType = fromAccountTypes.contains(entryState.fromAccountType)
        ? entryState.fromAccountType : null;
    final validToAccountType = toAccountTypes.contains(entryState.toAccountType)
        ? entryState.toAccountType : null;
    


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
                      value: validFromAccountType,
                      hint: const Text('유형'),
                      items: fromAccountTypes.map((type) => DropdownMenuItem(value: type, child: Text(_getAccountTypeLabel(type)))).toList(),
                      onChanged: (type) {
                        if (type != null) entryViewModel.setFromAccountType(type);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    // --- 👇 [수정] DropdownButtonFormField<String>으로 변경 ---
                    child: DropdownButtonFormField<String>(
                      value: entryState.fromAccountId, 
                      hint: const Text('계정과목'),
                      items: fromAccounts.map((account) => DropdownMenuItem(
                        value: account.id, // 아이템의 값도 ID 사용
                        child: Text(account.name),
                      )).toList(),
                      onChanged: (accountId) {
                        if (accountId != null) {
                          // ID로 전체 목록에서 Account 객체를 찾아 ViewModel에 전달
                          final selectedAccount = allAccounts.firstWhere((a) => a.id == accountId);
                          entryViewModel.setFromAccount(selectedAccount);
                        }
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
                      value: validToAccountType,
                      hint: const Text('유형'),
                      items: toAccountTypes.map((type) => DropdownMenuItem(value: type, child: Text(_getAccountTypeLabel(type)))).toList(),
                      onChanged: (type) {
                        if (type != null) entryViewModel.setToAccountType(type);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: entryState.toAccountId, // 값으로 ID 사용
                      hint: const Text('계정과목'),
                      items: toAccounts.map((account) => DropdownMenuItem(
                        value: account.id, // 아이템의 값도 ID 사용
                        child: Text(account.name),
                      )).toList(),
                      onChanged: (accountId) {
                        if (accountId != null) {
                          final selectedAccount = allAccounts.firstWhere((a) => a.id == accountId);
                          entryViewModel.setToAccount(selectedAccount);
                        }
                      },
                    ),
                  ),
                ],
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
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
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

                    setState(() { _isLoading = true; });

                    try {
                      final List<JournalEntry> entries = [
                        JournalEntry(accountId: currentState.toAccountId!, type: EntryType.debit, amount: currentState.amount),
                        JournalEntry(accountId: currentState.fromAccountId!, type: EntryType.credit, amount: currentState.amount),
                      ];
                      
                      if (_isEditMode) {
                        final updatedTransaction = Transaction(
                          id: widget.transaction!.id,
                        date: entryState.date,
                        description: entryState.description.isEmpty 
                            ? allAccounts.firstWhere((a) => a.id == entryState.toAccountId).name 
                            : entryState.description,
                        entries: entries,
                        );
                        await ref.read(transactionProvider.notifier).updateTransaction(updatedTransaction);
                      } else {
                        final newTransaction = Transaction(
                          id: const Uuid().v4(),
                          date: currentState.date,
                          description: entryState.description.isEmpty 
                            ? allAccounts.firstWhere((a) => a.id == entryState.toAccountId).name 
                            : entryState.description,
                        entries: entries,
                        );
                        await ref.read(transactionProvider.notifier).addTransaction(newTransaction);
                      }
                      
                      if (mounted) context.go('/');

                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() { _isLoading = false; });
                      }
                    }
                  },
                  child: const Text('저장하기'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAccountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.asset: return '자산';
      case AccountType.liability: return '부채';
      case AccountType.equity: return '자본';
      case AccountType.revenue: return '수익';
      case AccountType.expense: return '비용';
    }
  }
}