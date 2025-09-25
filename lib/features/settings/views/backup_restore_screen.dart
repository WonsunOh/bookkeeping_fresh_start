import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/responsive_layout.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(title: const Text('백업 및 복원')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildBackupCard(),
              const SizedBox(height: 16),
              _buildRestoreCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  '백업 정보',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('• 모든 거래 내역과 계정과목이 백업됩니다'),
            const Text('• 백업 파일은 JSON 형식으로 저장됩니다'),
            const Text('• 복원 시 기존 데이터는 덮어쓰여집니다'),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard() {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.2),
          child: Icon(Icons.backup, color: Colors.green.shade600),
        ),
        title: const Text('데이터 백업'),
        subtitle: const Text('모든 거래 내역을 파일로 저장합니다'),
        trailing: _isLoading 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.arrow_forward_ios),
        onTap: _isLoading ? null : _performBackup,
      ),
    );
  }

  Widget _buildRestoreCard() {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.2),
          child: Icon(Icons.restore, color: Colors.orange.shade600),
        ),
        title: const Text('데이터 복원'),
        subtitle: const Text('백업 파일에서 데이터를 가져옵니다'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: _performRestore,
      ),
    );
  }

  Future<void> _performBackup() async {
    setState(() => _isLoading = true);
    
    try {
      // 실제 백업 로직은 나중에 구현
      await Future.delayed(const Duration(seconds: 2)); // 시뮬레이션
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('백업이 완료되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('백업 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performRestore() async {
    final confirmed = await _showRestoreConfirmDialog();
    if (!confirmed) return;

    // 복원 로직 구현 예정
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('복원 기능은 곧 구현될 예정입니다')),
    );
  }

  Future<bool> _showRestoreConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 복원 확인'),
        content: const Text(
          '복원을 진행하면 현재의 모든 데이터가 삭제되고 '
          '백업 파일의 데이터로 대체됩니다.\n\n'
          '정말 복원하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('복원'),
          ),
        ],
      ),
    ) ?? false;
  }
}