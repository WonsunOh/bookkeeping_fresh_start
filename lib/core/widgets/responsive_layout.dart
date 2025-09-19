// lib/core/widgets/responsive_layout.dart

import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  /// 이 레이아웃이 감쌀 자식 위젯입니다. (일반적으로 Scaffold)
  final Widget child;

  /// 화면의 최대 너비를 지정합니다. 기본값은 1200입니다.
  final double maxWidth;

  /// 콘텐츠 영역 바깥의 배경색을 지정합니다.
  final Color backgroundColor;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.backgroundColor = const Color(0xFFF5F5F5), // 밝은 회색 계열
  });

  @override
  Widget build(BuildContext context) {
    // 1. Container를 사용하여 웹페이지 전체의 배경색을 지정합니다.
    return Container(
      color: backgroundColor,
      child: Center(
        // 2. Center 위젯으로 내부 콘텐츠를 중앙에 배치합니다.
        child: ConstrainedBox(
          // 3. ConstrainedBox를 사용하여 AppBar를 포함한 자식 위젯(Scaffold)의
          //    최대 너비를 제한합니다.
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}