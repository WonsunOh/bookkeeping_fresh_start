class KoreanErrorMessages {
  static const Map<String, String> _messages = {
    'network_error': '네트워크 연결을 확인해주세요',
    'server_error': '서버 오류가 발생했습니다',
    'validation_error': '입력한 정보를 확인해주세요',
    'permission_denied': '권한이 없습니다',
    'not_found': '요청한 데이터를 찾을 수 없습니다',
    'timeout': '요청 시간이 초과되었습니다',
    'unknown_error': '알 수 없는 오류가 발생했습니다',
    
    // Firebase specific
    'firebase_auth_failed': '인증에 실패했습니다',
    'firebase_network': 'Firebase 연결에 문제가 있습니다',
    'firestore_permission_denied': 'Firestore 접근 권한이 없습니다',
    
    // Validation specific
    'empty_field': '필수 입력 항목입니다',
    'invalid_amount': '올바른 금액을 입력해주세요',
    'invalid_date': '올바른 날짜를 선택해주세요',
    'duplicate_name': '이미 존재하는 이름입니다',
  };
  
  static String getMessage(String key, [String? defaultMessage]) {
    return _messages[key] ?? defaultMessage ?? '오류가 발생했습니다';
  }
  
  static String getFormattedMessage(String key, Map<String, String> params) {
    String message = getMessage(key);
    params.forEach((key, value) {
      message = message.replaceAll('{$key}', value);
    });
    return message;
  }
}