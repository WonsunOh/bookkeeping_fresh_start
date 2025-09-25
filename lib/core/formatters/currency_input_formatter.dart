// lib/core/formatters/currency_input_formatter.dart

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    
    // 입력이 완전히 삭제된 경우
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // 숫자만 추출
    final String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // 숫자가 없으면 빈 문자열 반환
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    try {
      // 숫자를 double로 변환
      final double value = double.parse(digitsOnly);
      
      // 천 단위 구분자 추가
      final formatter = NumberFormat.decimalPattern('ko_KR');
      final String formattedText = formatter.format(value);

      // 안전한 커서 위치 계산 (항상 끝으로)
      final int newOffset = formattedText.length;

      // 범위 체크 (매우 중요!)
      final int safeOffset = newOffset.clamp(0, formattedText.length);

      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: safeOffset),
      );
    } catch (e) {
      // 파싱 실패 시 이전 값 유지
      return oldValue;
    }
  }
}