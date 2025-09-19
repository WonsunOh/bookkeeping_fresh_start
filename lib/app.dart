// lib/app.dart

import 'package:flutter/material.dart';
import 'core/router.dart';
// 1. 방금 만든 테마 파일을 import 합니다.
import 'core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  // 3. build 메서드에서 WidgetRef ref를 제거합니다.
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: '복식부기 장부',
      
      // --- 2. 테마 설정을 추가합니다. ---
      theme: AppTheme.lightTheme,       // 밝은 모드일 때 사용할 테마
      darkTheme: AppTheme.darkTheme,     // 어두운 모드일 때 사용할 테마
      themeMode: ThemeMode.system,     // 시스템 설정을 따르도록 지정
      // -----------------------------
    );
  }
}