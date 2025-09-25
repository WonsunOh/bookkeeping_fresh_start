import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/transaction/views/home_screen.dart';
import '../utils/korean_error_messages.dart';
import 'improved_error_widget.dart' hide ImprovedLoadingWidget;

class ImprovedAsyncBuilder<T> extends StatelessWidget {
  final AsyncValue<T> asyncValue;
  final Widget Function(T data) dataBuilder;
  final String loadingMessage;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ImprovedAsyncBuilder({
    super.key,
    required this.asyncValue,
    required this.dataBuilder,
    this.loadingMessage = '데이터를 불러오는 중...',
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: dataBuilder,
      loading: () => ImprovedLoadingWidget(message: loadingMessage),
      error: (error, stackTrace) => ImprovedErrorWidget(
        message: errorMessage ?? _getErrorMessage(error),
        onRetry: onRetry,
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error.toString().contains('network')) {
      return KoreanErrorMessages.getMessage('network_error');
    } else if (error.toString().contains('permission')) {
      return KoreanErrorMessages.getMessage('permission_denied');
    } else if (error.toString().contains('timeout')) {
      return KoreanErrorMessages.getMessage('timeout');
    } else {
      return KoreanErrorMessages.getMessage('unknown_error');
    }
  }
}