// lib/features/repeating_transactions/views/add_edit_repeating_transaction_screen.dart

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
import '../../../data/models/repeating_transaction.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/repeating_transaction_repository.dart';
import '../../transaction/viewmodels/account_provider.dart';
import '../viewmodels/repeating_transaction_entry_viewmodel.dart';

class AddEditRepeatingTransactionScreen extends ConsumerStatefulWidget {
  final RepeatingTransaction? rule;
  final Transaction? transaction;

  const AddEditRepeatingTransactionScreen({super.key, this.rule, this.transaction});

  @override
  ConsumerState<AddEditRepeatingTransactionScreen> createState() =>
      _AddEditRepeatingTransactionScreenState();
}

class _AddEditRepeatingTransactionScreenState
    extends ConsumerState<AddEditRepeatingTransactionScreen> {
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  
  bool _isInitialized = false;
  bool _isLoading = false;

  bool get _isEditMode => widget.rule != null;

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final entryState = ref.read(repeatingEntryProvider);
    if (entryState.fromAccount == null ||
        entryState.toAccount == null ||
        entryState.amount <= 0 ||
        entryState.description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 올바르게 입력해주세요.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final repository = ref.read(repeatingTransactionRepositoryProvider);
      final rule = RepeatingTransaction(
        id: _isEditMode ? widget.rule!.id : const Uuid().v4(),
        description: entryState.description,
        amount: entryState.amount,
        fromAccountId: entryState.fromAccount!.id,
        toAccountId: entryState.toAccount!.id,
        entryType: entryState.entryType,
        frequency: entryState.frequency,
        nextDueDate: entryState.nextDueDate,
        endDate: entryState.endDate,
      );

      if (_isEditMode) {
        await repository.update(rule);
      } else {
        await repository.add(rule);
      }
      
      if (mounted) context.pop();

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
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final entryViewModel = ref.read(repeatingEntryProvider.notifier);
    
    final entryState = ref.watch(repeatingEntryProvider);
    // 컨트롤러와 ViewModel 상태 동기화
    final formattedAmount = NumberFormat.decimalPattern('ko_KR').format(entryState.amount);
    if (_amountController.text != formattedAmount) {
      _amountController.text = formattedAmount;
      _amountController.selection = TextSelection.fromPosition(TextPosition(offset: _amountController.text.length));
    }
    if (_memoController.text != entryState.description) {
      _memoController.text = entryState.description;
       _memoController.selection = TextSelection.fromPosition(TextPosition(offset: _memoController.text.length));
    }

    return accountsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(_isEditMode ? '반복 거래 수정' : '반복 거래 추가')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('오류')),
        body: Center(child: Text('계정 정보를 불러오는 데 실패했습니다: $err')),
      ),
      data: (accounts) {
        // --- 👇 여기가 핵심 수정 부분입니다 ---
        if (!_isInitialized) {
          // Future.microtask를 사용하여 build가 끝난 직후에 상태를 변경합니다.
          Future.microtask(() {
            if (_isEditMode) {
              entryViewModel.initializeForEdit(widget.rule!, accounts);
            } else if (widget.transaction != null) {
              entryViewModel.initializeFromTransaction(widget.transaction!, accounts);
            }
          });
          _isInitialized = true;
        }
        // ------------------------------------

        final assetAccounts = accounts.where((a) => a.type == AccountType.asset).toList();
        final expenseAccounts = accounts.where((a) => a.type == AccountType.expense).toList();
        final revenueAccounts = accounts.where((a) => a.type == AccountType.revenue).toList();
        final equityAccounts = accounts.where((a) => a.type == AccountType.equity).toList();

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
          } else {
            toAccounts = assetAccounts;
            toAccountLabel = '어디로 (자산)';
          }
        }

        final validFromAccount =
            entryState.fromAccount != null && fromAccounts.contains(entryState.fromAccount)
                ? entryState.fromAccount
                : null;
        final validToAccount =
            entryState.toAccount != null && toAccounts.contains(entryState.toAccount)
                ? entryState.toAccount
                : null;
        final dateFormat = DateFormat('yyyy.MM.dd');

        return ResponsiveLayout(
          child: Scaffold(
            appBar: AppBar(
              title: Text(_isEditMode ? '반복 거래 수정' : '반복 거래 추가'),
            ),
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
                  TextFormField(
                    controller: _memoController,
                    decoration: const InputDecoration(
                        labelText: '메모 (예: 월급, 통신비)', border: OutlineInputBorder()),
                    onChanged: (value) => entryViewModel.setDescription(value),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Account>(
                    value: validFromAccount,
                    decoration: InputDecoration(
                        labelText: fromAccountLabel,
                        border: const OutlineInputBorder()),
                    items: fromAccounts
                        .map((account) => DropdownMenuItem(
                            value: account, child: Text(account.name)))
                        .toList(),
                    onChanged: (account) {
                      if (account != null) entryViewModel.setFromAccount(account);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Account>(
                    value: validToAccount,
                    decoration: InputDecoration(
                        labelText: toAccountLabel,
                        border: const OutlineInputBorder()),
                    items: toAccounts
                        .map((account) => DropdownMenuItem(
                            value: account, child: Text(account.name)))
                        .toList(),
                    onChanged: (account) {
                      if (account != null) entryViewModel.setToAccount(account);
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
                  const Divider(height: 32),
                  DropdownButtonFormField<Frequency>(
                    value: entryState.frequency,
                    decoration: const InputDecoration(
                        labelText: '반복 주기', border: OutlineInputBorder()),
                    items: Frequency.values
                        .map((f) => DropdownMenuItem(
                            value: f, child: Text(_getFrequencyLabel(f))))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) entryViewModel.setFrequency(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('시작 예정일'),
                    trailing: TextButton(
                      child: Text(dateFormat.format(entryState.nextDueDate)),
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: entryState.nextDueDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (pickedDate != null) {
                          entryViewModel.setNextDueDate(pickedDate);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('규칙 저장하기'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getFrequencyLabel(Frequency freq) {
    switch (freq) {
      case Frequency.daily: return '매일';
      case Frequency.weekly: return '매주';
      case Frequency.monthly: return '매월';
      case Frequency.quarterly: return '매분기';
      case Frequency.yearly: return '매년';
    }
  }
}