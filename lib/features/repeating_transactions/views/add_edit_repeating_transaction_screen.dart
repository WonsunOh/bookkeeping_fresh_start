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
      data: (allAccounts) {
        if (!_isInitialized) {
          Future.microtask(() {
            if (_isEditMode) {
              entryViewModel.initializeForEdit(widget.rule!, allAccounts);
            } else if (widget.transaction != null) {
              entryViewModel.initializeFromTransaction(widget.transaction!, allAccounts);
            }
          });
          _isInitialized = true;
        }

        // ✅ 거래내역과 같은 로직으로 변경
        final List<AccountType> fromAccountTypes;
        final String fromAccountLabel;
        final List<AccountType> toAccountTypes;
        final String toAccountLabel;

        switch (entryState.entryType) {
          case EntryScreenType.income:
            fromAccountTypes = [AccountType.revenue, AccountType.equity, AccountType.liability, AccountType.expense];
            fromAccountLabel = '어디서 (수익/자본/부채/비용)';
            toAccountTypes = [AccountType.asset, AccountType.liability];
            toAccountLabel = '어디로 (자산/부채)';
            break;
          case EntryScreenType.expense:
            fromAccountTypes = [AccountType.asset, AccountType.liability];
            fromAccountLabel = '어디서 (자산/부채)';
            toAccountTypes = [AccountType.expense, AccountType.equity, AccountType.liability];
            toAccountLabel = '무엇을 위해 (비용/자본/부채)';
            break;
          case EntryScreenType.transfer:
            fromAccountTypes = [AccountType.asset];
            fromAccountLabel = '어디서 (자산)';
            toAccountTypes = [AccountType.asset, AccountType.liability];
            toAccountLabel = '어디로 (자산/부채)';
            break;
        }

        // ✅ 계정 유형별로 필터링된 계정 목록
        final fromAccountType = entryState.fromAccount?.type;
        final toAccountType = entryState.toAccount?.type;

        final fromAccounts = fromAccountType == null
            ? <Account>[]
            : allAccounts.where((a) => a.type == fromAccountType).toList();
        final toAccounts = toAccountType == null
            ? <Account>[]
            : allAccounts.where((a) => a.type == toAccountType).toList();

        // ✅ 유효성 체크
        final validFromAccount = entryState.fromAccount != null && fromAccounts.contains(entryState.fromAccount)
            ? entryState.fromAccount
            : null;
        final validToAccount = entryState.toAccount != null && toAccounts.contains(entryState.toAccount)
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

                  // ✅ 거래내역과 같은 형식: From 계정 선택 (유형 + 계정과목)
                  Text(fromAccountLabel, style: Theme.of(context).textTheme.titleSmall),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<AccountType>(
                          value: fromAccountTypes.contains(fromAccountType) ? fromAccountType : null,
                          hint: const Text('유형'),
                          items: fromAccountTypes.toSet().map((type) => 
                            DropdownMenuItem(value: type, child: Text(_getAccountTypeLabel(type)))
                          ).toList(),
                          onChanged: (type) {
                            if (type != null) {
                              // 유형이 바뀌면 해당 유형의 첫 번째 계정을 자동 선택
                              final accountsOfType = allAccounts.where((a) => a.type == type).toList();
                              if (accountsOfType.isNotEmpty) {
                                entryViewModel.setFromAccount(accountsOfType.first);
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<Account>(
                          value: validFromAccount,
                          hint: const Text('계정과목'),
                          items: fromAccounts.map((account) => 
                            DropdownMenuItem(value: account, child: Text(account.name))
                          ).toList(),
                          onChanged: (Account? newAccount) {
                            if (newAccount != null) entryViewModel.setFromAccount(newAccount);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ✅ 거래내역과 같은 형식: To 계정 선택 (유형 + 계정과목)
                  Text(toAccountLabel, style: Theme.of(context).textTheme.titleSmall),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<AccountType>(
                          value: toAccountTypes.contains(toAccountType) ? toAccountType : null,
                          hint: const Text('유형'),
                          items: toAccountTypes.toSet().map((type) => 
                            DropdownMenuItem(value: type, child: Text(_getAccountTypeLabel(type)))
                          ).toList(),
                          onChanged: (type) {
                            if (type != null) {
                              // 유형이 바뀌면 해당 유형의 첫 번째 계정을 자동 선택
                              final accountsOfType = allAccounts.where((a) => a.type == type).toList();
                              if (accountsOfType.isNotEmpty) {
                                entryViewModel.setToAccount(accountsOfType.first);
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<Account>(
                          value: validToAccount,
                          hint: const Text('계정과목'),
                          items: toAccounts.map((account) => 
                            DropdownMenuItem(value: account, child: Text(account.name))
                          ).toList(),
                          onChanged: (account) {
                            if (account != null) entryViewModel.setToAccount(account);
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

  // ✅ 계정 유형 라벨 함수 추가 (거래내역과 동일)
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