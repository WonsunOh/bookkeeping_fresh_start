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
  AccountType _type = AccountType.expense; // 기본값
  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    // accountToEdit 객체가 있으면 수정 모드, 없으면 추가 모드
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
        // 수정 로직: 기존 ID를 사용하여 업데이트
        final updatedAccount = Account(
          id: widget.accountToEdit!.id,
          name: _name,
          type: _type,
        );
        repository.updateAccount(updatedAccount);
      } else {
        // 추가 로직: 새 ID를 생성하여 추가
        final newAccount = Account(
          id: const Uuid().v4(),
          name: _name,
          type: _type,
        );
        repository.addAccount(newAccount);
      }
      context.pop(); // 다이얼로그 닫기
    }
  }

  void _delete() {
    final repository = ref.read(accountRepositoryProvider);
    repository.deleteAccount(widget.accountToEdit!.id);
    context.pop(); // 다이얼로그 닫기
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditMode ? '계정과목 수정' : '새 계정과목 추가'),
      // AlertDialog의 content는 스크롤이 안되므로 SingleChildScrollView로 감싸줍니다.
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // content 크기에 맞게 높이 조절
            children: [
              TextFormField(
                initialValue: _name, // 수정 시 기존 이름 표시
                decoration: const InputDecoration(labelText: '이름'),
                validator: (value) => (value == null || value.isEmpty) ? '이름을 입력하세요.' : null,
                onSaved: (value) => _name = value!,
                autofocus: true, // 다이얼로그가 열리면 바로 입력 시작
              ),
              const SizedBox(height: 24),
            const Text('유형', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            // --- DropdownButtonFormField를 아래 RadioListTile들로 교체 ---
            // Column을 사용하여 라디오 버튼들을 세로로 배치합니다.
            // AlertDialog는 스크롤이 안되므로, 내용이 길어질 경우를 대비해
            // Flexible과 SingleChildScrollView를 함께 사용합니다.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AccountType.values.map((type) {
                    return RadioListTile<AccountType>(
                      title: Text(_getAccountTypeLabel(type)),
                      value: type,
                      groupValue: _type,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _type = value;
                          });
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
      actions: [
        // 수정 모드일 때만 '삭제' 버튼 표시
        if (_isEditMode)
          TextButton(
            onPressed: () {
              // 삭제 확인 다이얼로그를 한 번 더 보여줌
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('삭제 확인'),
                  content: Text('\'$_name\' 계정과목을 정말 삭제하시겠습니까?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('취소')),
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
        const Spacer(), // 버튼들을 양쪽 끝으로 밀어냄
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
      case AccountType.asset: return '자산';
      case AccountType.liability: return '부채';
      case AccountType.equity: return '자본';
      case AccountType.revenue: return '수익';
      case AccountType.expense: return '비용';
    }
  }
}