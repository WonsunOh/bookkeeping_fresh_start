// lib/features/settings/widgets/add_account_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/enums.dart';
import '../../../data/models/account.dart';
import '../../transaction/viewmodels/account_provider.dart';

// 추가와 수정을 모두 처리하는 다이얼로그
class AddEditAccountDialog extends ConsumerStatefulWidget {
  // 수정 모드일 경우, 기존 Account 객체를 전달받음
  final Account? accountToEdit;

  const AddEditAccountDialog({super.key, this.accountToEdit});

  @override
  ConsumerState<AddEditAccountDialog> createState() => _AddEditAccountDialogState();
}

class _AddEditAccountDialogState extends ConsumerState<AddEditAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  AccountType _type = AccountType.asset; // 기본값을 '자산'으로 변경
  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.accountToEdit != null;
    if (_isEditMode) {
      _name = widget.accountToEdit!.name;
      _type = widget.accountToEdit!.type;
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final repository = ref.read(accountRepositoryProvider);

      if (_isEditMode) {
        final updatedAccount = Account(
          id: widget.accountToEdit!.id,
          name: _name,
          type: _type,
        );
        repository.updateAccount(updatedAccount);
      } else {
        final newAccount = Account(
          id: const Uuid().v4(),
          name: _name,
          type: _type,
        );
        repository.addAccount(newAccount);
      }
      context.pop();
    }
  }

  void _delete() {
    final repository = ref.read(accountRepositoryProvider);
    repository.deleteAccount(widget.accountToEdit!.id);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditMode ? '계정과목 수정' : '새 계정과목 추가'),
      // --- 👇 SingleChildScrollView로 감싸서 오버플로우 에러 해결 ---
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: '이름'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? '이름을 입력하세요.' : null,
                onSaved: (value) => _name = value!,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AccountType>(
                value: _type,
                decoration: const InputDecoration(labelText: '유형'),
                isExpanded: false,
                items: AccountType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getAccountTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _type = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      // --------------------------------------------------------
      actions: [
        if (_isEditMode)
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('삭제 확인'),
                  content: Text('\'$_name\' 계정과목을 정말 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('취소')),
                    TextButton(
                      onPressed: _delete,
                      child: const Text('삭제', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('저장'),
        ),
      ],
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