import 'package:flutter/material.dart';

class VirtualizedTransactionList extends StatelessWidget {
  final List<dynamic> items;
  final Widget Function(dynamic item, int index) itemBuilder;
  final Widget? separator;
  final EdgeInsetsGeometry? padding;

  const VirtualizedTransactionList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.separator,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('데이터가 없습니다'));
    }

    return ListView.separated(
      padding: padding ?? const EdgeInsets.all(8),
      itemCount: items.length,
      cacheExtent: 1000, // 성능 최적화: 미리 렌더링할 픽셀 수
      addAutomaticKeepAlives: false, // 메모리 절약
      addRepaintBoundaries: false, // 불필요한 레이어 제거
      itemBuilder: (context, index) {
        return RepaintBoundary( // 개별 아이템 리페인트 경계
          child: itemBuilder(items[index], index),
        );
      },
      separatorBuilder: (context, index) => 
          separator ?? const SizedBox(height: 4),
    );
  }
}