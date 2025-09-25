import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          // 테마 설정
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('테마'),
              subtitle: Text(_getThemeText(currentTheme)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showThemeDialog(context, ref),
            ),
          ),
          
          // 백업 및 복원
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('백업 및 복원'),
              subtitle: const Text('데이터 백업 및 복원'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.push('/backup'),
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return '라이트 모드';
      case ThemeMode.dark: return '다크 모드';
      case ThemeMode.system: return '시스템 설정';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테마 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) =>
            RadioListTile<ThemeMode>(
              title: Text(_getThemeText(mode)),
              value: mode,
              groupValue: ref.read(themeProvider),
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ).toList(),
        ),
      ),
    );
  }
}