// lib/features/transaction/views/transaction_entry_screen.dart (오류 수정 버전)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/enums.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/improved_error_widget.dart';
import '../../../core/widgets/improved_async_builder.dart';
import '../../../core/widgets/korean_currency_formatter.dart';
import '../../../core/utils/korean_error_messages.dart';
import '../../../core/formatters/currency_input_formatter.dart';
import '../../../data/models/account.dart';
import '../../../data/models/journal_entry.dart';
import '../../../data/models/transaction.dart';
import '../viewmodels/account_provider.dart';
import '../viewmodels/transaction_entry_viewmodel.dart';
import '../../../data/repositories/transaction_repository.dart';

class TransactionEntryScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;
  const TransactionEntryScreen({super.key, this.transaction});

  @override
  ConsumerState<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends ConsumerState<TransactionEntryScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _memoFocusNode = FocusNode();
  
  late TabController _tabController;
  bool _isInitialized = false;
  bool _isLoading = false;

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    _amountFocusNode.dispose();
    _memoFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entryState = ref.watch(transactionEntryProvider);
    final entryViewModel = ref.read(transactionEntryProvider.notifier);
    final accountsAsync = ref.watch(accountsStreamProvider);

    // 컨트롤러와 ViewModel 상태 동기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllers(entryState);
    });

    return ImprovedAsyncBuilder(
      asyncValue: accountsAsync,
      loadingMessage: '계정 정보를 불러오는 중...',
      errorMessage: '계정 정보를 불러올 수 없습니다.',
      onRetry: () => ref.refresh(accountsStreamProvider),
      dataBuilder: (allAccounts) => _buildEntryScreen(context, entryState, entryViewModel, allAccounts),
    );
  }

  Widget _buildEntryScreen(
    BuildContext context,
    TransactionEntryState entryState,
    TransactionEntryViewModel entryViewModel,
    List<Account> allAccounts,
  ) {
    // 초기화
    if (!_isInitialized) {
      Future.microtask(() {
        if (_isEditMode) {
          entryViewModel.initializeForEdit(widget.transaction!, allAccounts);
        } else {
          entryViewModel.setEntryType(EntryScreenType.expense);
        }
      });
      _isInitialized = true;
    }

    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? '거래 수정' : '거래 기록'),
          bottom: TabBar(
            controller: _tabController,
            onTap: (index) {
              final types = [EntryScreenType.expense, EntryScreenType.income, EntryScreenType.transfer];
              entryViewModel.setEntryType(types[index]);
            },
            tabs: const [
              Tab(text: '지출', icon: Icon(Icons.trending_down, size: 20)),
              Tab(text: '수입', icon: Icon(Icons.trending_up, size: 20)),
              Tab(text: '이체', icon: Icon(Icons.swap_horiz, size: 20)),
            ],
          ),
          actions: [
            if (_isEditMode)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _showDeleteDialog,
                tooltip: '삭제',
              ),
          ],
        ),
        body: _isLoading
            ? const ImprovedLoadingWidget(message: '거래를 저장하는 중...')
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildEntryForm(context, entryState, entryViewModel, allAccounts),
                  _buildEntryForm(context, entryState, entryViewModel, allAccounts),
                  _buildEntryForm(context, entryState, entryViewModel, allAccounts),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isLoading ? null : () => _saveTransaction(entryState, allAccounts),
          icon: Icon(_isEditMode ? Icons.save : Icons.check),
          label: Text(_isEditMode ? '수정' : '저장'),
        ),
      ),
    );
  }

  Widget _buildEntryForm(
    BuildContext context,
    TransactionEntryState entryState,
    TransactionEntryViewModel entryViewModel,
    List<Account> allAccounts,
  ) {
    final fromAccountTypes = _getFromAccountTypes(entryState.entryType);
    final toAccountTypes = _getToAccountTypes(entryState.entryType);
    
    final fromAccounts = entryState.fromAccountType == null
        ? <Account>[]
        : allAccounts.where((a) => a.type == entryState.fromAccountType).toList();
    
    final toAccounts = entryState.toAccountType == null
        ? <Account>[]
        : allAccounts.where((a) => a.type == entryState.toAccountType).toList();

    final validFromAccount = entryState.fromAccountId != null && 
        fromAccounts.any((a) => a.id == entryState.fromAccountId)
        ? fromAccounts.firstWhere((a) => a.id == entryState.fromAccountId) 
        : null;
        
    final validToAccount = entryState.toAccountId != null && 
        toAccounts.any((a) => a.id == entryState.toAccountId)
        ? toAccounts.firstWhere((a) => a.id == entryState.toAccountId) 
        : null;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 거래 유형별 설명
            _buildTypeExplanation(entryState.entryType),
            const SizedBox(height: 24),

            // 금액 입력
            _buildAmountField(context, entryViewModel),
            const SizedBox(height: 20),

            // 날짜 선택
            _buildDateField(context, entryState, entryViewModel),
            const SizedBox(height: 20),

            // 출발 계정
            _buildAccountSection(
              context,
              title: _getFromAccountLabel(entryState.entryType),
              accountTypes: fromAccountTypes,
              selectedType: entryState.fromAccountType,
              accounts: fromAccounts,
              selectedAccount: validFromAccount,
              onTypeChanged: entryViewModel.setFromAccountType,
              onAccountChanged: (account) => entryViewModel.setFromAccount(account!),
            ),
            const SizedBox(height: 20),

            // 도착 계정
            _buildAccountSection(
              context,
              title: _getToAccountLabel(entryState.entryType),
              accountTypes: toAccountTypes,
              selectedType: entryState.toAccountType,
              accounts: toAccounts,
              selectedAccount: validToAccount,
              onTypeChanged: entryViewModel.setToAccountType,
              onAccountChanged: (account) => entryViewModel.setToAccount(account!),
            ),
            const SizedBox(height: 20),

            // 메모 입력
            _buildMemoField(context, entryViewModel),
            
            const SizedBox(height: 100), // FloatingActionButton을 위한 여백
          ],
        ),
      ),
    );
  }

  Widget _buildTypeExplanation(EntryScreenType type) {
    String title;
    String description;
    IconData icon;
    Color color;

    switch (type) {
      case EntryScreenType.expense:
        title = '지출 기록';
        description = '돈을 사용한 내역을 기록합니다.\n자산에서 비용으로 돈이 이동합니다.';
        icon = Icons.trending_down;
        color = Colors.red;
        break;
      case EntryScreenType.income:
        title = '수입 기록';
        description = '돈을 받은 내역을 기록합니다.\n수입에서 자산으로 돈이 이동합니다.';
        icon = Icons.trending_up;
        color = Colors.green;
        break;
      case EntryScreenType.transfer:
        title = '계좌 이체';
        description = '계좌 간 돈을 옮긴 내역을 기록합니다.\n한 자산에서 다른 자산으로 돈이 이동합니다.';
        icon = Icons.swap_horiz;
        color = Colors.blue;
        break;
    }

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField(BuildContext context, TransactionEntryViewModel entryViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '금액',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          focusNode: _amountFocusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(),
          ],
          decoration: const InputDecoration(
            hintText: '0',
            suffixText: '원',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
          ),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return KoreanErrorMessages.getMessage('empty_field');
            }
            final cleanValue = value.replaceAll(',', '');
            final amount = double.tryParse(cleanValue);
            if (amount == null || amount <= 0) {
              return KoreanErrorMessages.getMessage('invalid_amount');
            }
            return null;
          },
          onChanged: (value) {
            final cleanValue = value.replaceAll(',', '');
            final amount = double.tryParse(cleanValue) ?? 0;
            entryViewModel.setAmount(amount);
          },
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context, TransactionEntryState entryState, TransactionEntryViewModel entryViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '날짜',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, entryState, entryViewModel),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Text(
                  KoreanDateFormatter.formatDateWithDay(entryState.date),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                Text(
                  KoreanDateFormatter.formatRelative(entryState.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(
    BuildContext context, {
    required String title,
    required List<AccountType> accountTypes,
    required AccountType? selectedType,
    required List<Account> accounts,
    required Account? selectedAccount,
    required Function(AccountType) onTypeChanged,
    required Function(Account?) onAccountChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<AccountType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: '계정 유형',
                  border: OutlineInputBorder(),
                ),
                items: accountTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(_getAccountTypeDisplayName(type)),
                )).toList(),
                onChanged: (type) {
                  if (type != null) onTypeChanged(type);
                },
                validator: (value) {
                  if (value == null) {
                    return '계정 유형을 선택해주세요';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<Account>(
                value: selectedAccount,
                decoration: const InputDecoration(
                  labelText: '계정과목',
                  border: OutlineInputBorder(),
                ),
                items: accounts.map((account) => DropdownMenuItem(
                  value: account,
                  child: Text(account.name),
                )).toList(),
                onChanged: onAccountChanged,
                validator: (value) {
                  if (value == null) {
                    return '계정과목을 선택해주세요';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMemoField(BuildContext context, TransactionEntryViewModel entryViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '메모 (선택사항)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _memoController,
          focusNode: _memoFocusNode,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '거래에 대한 메모를 입력하세요',
            border: OutlineInputBorder(),
          ),
          onChanged: entryViewModel.setDescription,
        ),
      ],
    );
  }

  // 헬퍼 메서드들
  void _syncControllers(TransactionEntryState entryState) {
    final formattedAmount = KoreanCurrencyFormatter.formatNumber(entryState.amount);
    if (_amountController.text != formattedAmount) {
      _amountController.text = formattedAmount;
    }
    if (_memoController.text != entryState.description) {
      _memoController.text = entryState.description;
    }
  }

  List<AccountType> _getFromAccountTypes(EntryScreenType type) {
    switch (type) {
      case EntryScreenType.income:
        return [AccountType.revenue, AccountType.equity, AccountType.liability];
      case EntryScreenType.expense:
        return [AccountType.asset, AccountType.liability];
      case EntryScreenType.transfer:
        return [AccountType.asset];
    }
  }

  List<AccountType> _getToAccountTypes(EntryScreenType type) {
    switch (type) {
      case EntryScreenType.income:
        return [AccountType.asset, AccountType.liability];
      case EntryScreenType.expense:
        return [AccountType.expense, AccountType.equity];
      case EntryScreenType.transfer:
        return [AccountType.asset, AccountType.liability];
    }
  }

  String _getFromAccountLabel(EntryScreenType type) {
    switch (type) {
      case EntryScreenType.income:
        return '어디서 (수입/자본/부채)';
      case EntryScreenType.expense:
        return '어디서 (자산/부채)';
      case EntryScreenType.transfer:
        return '어디서 (자산)';
    }
  }

  String _getToAccountLabel(EntryScreenType type) {
    switch (type) {
      case EntryScreenType.income:
        return '어디로 (자산/부채)';
      case EntryScreenType.expense:
        return '무엇을 위해 (비용/자본)';
      case EntryScreenType.transfer:
        return '어디로 (자산/부채)';
    }
  }

  String _getAccountTypeDisplayName(AccountType type) {
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

  Future<void> _selectDate(BuildContext context, TransactionEntryState entryState, TransactionEntryViewModel entryViewModel) async {
    final date = await showDatePicker(
      context: context,
      initialDate: entryState.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('ko', 'KR'),
      helpText: '날짜 선택',
      cancelText: '취소',
      confirmText: '확인',
    );

    if (date != null) {
      entryViewModel.setDate(date);
    }
  }

  Future<void> _saveTransaction(TransactionEntryState entryState, List<Account> allAccounts) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (entryState.fromAccountId == null || entryState.toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 계정과목을 선택해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ❌ 오류 부분: transactionProvider는 StreamProvider라서 notifier가 없음
      // ✅ 해결: TransactionRepository를 직접 사용
      final transactionRepository = ref.read(transactionRepositoryProvider);
      
      // ❌ 오류 부분: JournalEntry에 id 파라미터가 없음
      // ✅ 해결: id 파라미터 제거
      final entries = [
        JournalEntry(
          accountId: entryState.fromAccountId!,
          type: EntryType.credit,
          amount: entryState.amount,
        ),
        JournalEntry(
          accountId: entryState.toAccountId!,
          type: EntryType.debit,
          amount: entryState.amount,
        ),
      ];
      
      if (_isEditMode) {
        // 수정 로직
        final updatedTransaction = Transaction(
          id: widget.transaction!.id,
          date: entryState.date,
          description: entryState.description,
          entries: entries,
        );
        await transactionRepository.updateTransaction(updatedTransaction);
      } else {
        // 새 거래 추가
        final transaction = Transaction(
          id: const Uuid().v4(),
          date: entryState.date,
          description: entryState.description,
          entries: entries,
        );
        await transactionRepository.addTransaction(transaction);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? '거래가 수정되었습니다' : '거래가 저장되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDeleteDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('거래 삭제'),
        content: const Text('이 거래를 정말 삭제하시겠습니까?\n삭제된 거래는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        final transactionRepository = ref.read(transactionRepositoryProvider);
        await transactionRepository.deleteTransaction(widget.transaction!.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('거래가 삭제되었습니다'),
              backgroundColor: Colors.orange,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 중 오류가 발생했습니다: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}

