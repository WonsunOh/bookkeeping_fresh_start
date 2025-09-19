// lib/core/formatters/currency_input_formatter.dart

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 입력된 내용이 없으면 그대로 둡니다.
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // 쉼표 등 숫자 이외의 문자를 모두 제거합니다.
    final String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 제거 후 숫자가 없으면 빈 문자열로 처리합니다.
    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // 문자열을 숫자로 변환합니다.
    final double value = double.parse(newText);

    // intl 패키지를 사용하여 세 자리마다 쉼표를 찍는 포맷터를 생성합니다.
    final formatter = NumberFormat.decimalPattern('ko_KR');
    final String formattedText = formatter.format(value);

    // 포맷팅된 텍스트와 올바른 커서 위치를 반환합니다.
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}