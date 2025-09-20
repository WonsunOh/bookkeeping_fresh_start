// lib/features/settings/widgets/add_account_dialog.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums.dart';
import '../../../data/models/account.dart';
import '../../transaction/viewmodels/account_provider.dart';

class AddEditAccountDialog extends ConsumerStatefulWidget {
  final Account? accountToEdit;

  const AddEditAccountDialog({super.key, this.accountToEdit});

  @override
  ConsumerState<AddEditAccountDialog> createState() => _AddEditAccountDialogState();
}

class _AddEditAccountDialogState extends ConsumerState<AddEditAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  AccountType _selectedType = AccountType.asset;
  bool _isLoading = false;

  bool get isEditMode => widget.accountToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nameController.text = widget.accountToEdit!.name;
      _selectedType = widget.accountToEdit!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_isLoading) return;
      setState(() { _isLoading = true; });

      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      try {
        final viewModel = ref.read(accountViewModelProvider.notifier);
        final accountName = _nameController.text.trim();

        if (isEditMode) {
          await viewModel.updateAccount(
            id: widget.accountToEdit!.id,
            name: accountName,
            type: _selectedType,
          );
        } else {
          await viewModel.addAccount(name: accountName, type: _selectedType);
        }
        
        navigator.pop();

      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('저장 중 오류 발생: $e')));
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final viewModel = ref.read(accountViewModelProvider.notifier);
      await viewModel.deleteAccount(widget.accountToEdit!.id);
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('삭제 중 오류 발생: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '계정과목 수정' : '계정과목 추가'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final bool? shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('삭제 확인'),
                    content: Text('\'${_nameController.text}\' 계정과목을 정말 삭제하시겠습니까?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                
                if (shouldDelete == true) {
                  _delete();
                }
              },
            ),
          IconButton(icon: const Icon(Icons.check), onPressed: _submit),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '계정과목 이름'),
              validator: (value) => (value == null || value.trim().isEmpty) ? '이름을 입력해주세요.' : null,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AccountType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: '계정 유형'),
              isExpanded: false,
              items: AccountType.values.map((type) => DropdownMenuItem(value: type, child: Text(_getAccountTypeLabel(type)))).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ]
          ],
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