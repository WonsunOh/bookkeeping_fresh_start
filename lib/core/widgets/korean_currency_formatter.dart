import 'package:intl/intl.dart';

class KoreanCurrencyFormatter {
  static final _formatter = NumberFormat.decimalPattern('ko_KR');
  
  /// 숫자를 한국 통화 형식으로 포맷 (예: 1,234,567원)
  static String format(num amount) {
    return '${_formatter.format(amount)}원';
  }
  
  /// 숫자를 원화 기호와 함께 포맷 (예: ₩1,234,567)
  static String formatWithSymbol(num amount) {
    return '₩${_formatter.format(amount)}';
  }
  
  /// 천의 자리마다 콤마 추가 (예: 1,234,567)
  static String formatNumber(num amount) {
    return _formatter.format(amount);
  }
  
  /// 수입/지출에 따른 색상 포맷팅을 위한 헬퍼
  static (String, bool) formatWithSign(num amount) {
    final isPositive = amount >= 0;
    final formatted = format(amount.abs());
    return (isPositive ? '+$formatted' : '-$formatted', isPositive);
  }
}

class KoreanDateFormatter {
  /// 한국어 날짜 형식 (예: 2025년 1월 15일)
  static String formatDate(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(date);
  }
  
  /// 한국어 날짜와 요일 (예: 2025년 1월 15일 (수))
  static String formatDateWithDay(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(date);
  }
  
  /// 월/일만 표시 (예: 1월 15일)
  static String formatMonthDay(DateTime date) {
    return DateFormat('MM월 dd일', 'ko_KR').format(date);
  }
  
  /// 월/일과 요일 (예: 1월 15일 (수))
  static String formatMonthDayWithDay(DateTime date) {
    return DateFormat('MM월 dd일 (E)', 'ko_KR').format(date);
  }
  
  /// 시간 포함 (예: 2025년 1월 15일 오후 2시 30분)
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일 a h시 mm분', 'ko_KR').format(date);
  }
  
  /// 상대적 시간 표시 (예: 방금 전, 5분 전, 2시간 전, 어제, 일주일 전)
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}주 전';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else {
      return '${(difference.inDays / 365).floor()}년 전';
    }
  }
}
