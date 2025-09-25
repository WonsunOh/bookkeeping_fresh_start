// lib/features/admin/views/admin_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/responsive_layout.dart';

class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('관리 도구'),
          backgroundColor: Colors.deepPurple,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildMenuCard(
              context,
              title: '데이터 일관성 분석',
              subtitle: '거래 데이터의 패턴과 오류를 분석합니다',
              icon: Icons.analytics,
              color: Colors.orange,
              onTap: () => context.push('/admin/data-analysis'),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context,
              title: '계정 관리',
              subtitle: '계정과목 생성, 수정, 삭제',
              icon: Icons.account_tree,
              color: Colors.green,
              onTap: () => context.push('/accounts'),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context,
              title: '데이터 내보내기',
              subtitle: 'CSV, JSON 형태로 데이터 백업',
              icon: Icons.download,
              color: Colors.blue,
              onTap: () => context.push('/admin/export'),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context,
              title: '데이터베이스 정보',
              subtitle: '저장된 데이터 통계 및 상태',
              icon: Icons.storage,
              color: Colors.purple,
              onTap: () => context.push('/admin/database-info'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}