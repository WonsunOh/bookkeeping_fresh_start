// lib/core/services/biometric_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // 생체 인증 사용 가능 여부 확인
  Future<bool> isBiometricAvailable() async {

    if (kIsWeb) {
    debugPrint('Web platform detected, biometric not available');
    return false;
  }
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      debugPrint('생체 인증 가능 여부 확인 오류: $e');
      return false;
    }
  }
  
  // 사용 가능한 생체 인증 방법 목록 가져오기
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('사용 가능한 생체 인증 방법 조회 오류: $e');
      return [];
    }
  }
  
  // 생체 인증 실행
  Future<bool> authenticate({
    String reason = '앱에 접근하기 위해 생체 인증을 진행해주세요',
    bool biometricOnly = false,
  }) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: '생체 인증',
            cancelButton: '취소',
            deviceCredentialsRequiredTitle: '기기 잠금 설정 필요',
            deviceCredentialsSetupDescription: '기기에 잠금 설정이 되어있지 않습니다. 설정에서 잠금을 설정해주세요.',
            goToSettingsButton: '설정으로 이동',
            goToSettingsDescription: '설정에서 생체 인증을 활성화해주세요.',
          ),
        
        ],
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          sensitiveTransaction: true,
          stickyAuth: true,
        ),
      );
      
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('생체 인증 오류: ${e.message}');
      
      // 에러 코드별 처리
      switch (e.code) {
        case 'NotEnrolled':
          throw BiometricException('생체 인증이 등록되지 않았습니다. 기기 설정에서 등록해주세요.');
        case 'NotAvailable':
          throw BiometricException('생체 인증을 사용할 수 없습니다.');
        case 'PasscodeNotSet':
          throw BiometricException('기기에 잠금 설정이 되어있지 않습니다.');
        case 'UserCancel':
          throw BiometricException('사용자가 인증을 취소했습니다.');
        case 'LockedOut':
          throw BiometricException('너무 많은 시도로 인해 생체 인증이 일시적으로 잠겼습니다.');
        default:
          throw BiometricException('생체 인증 중 오류가 발생했습니다: ${e.message}');
      }
    } catch (e) {
      debugPrint('예상치 못한 생체 인증 오류: $e');
      return false;
    }
  }
  
  // 생체 인증 타입을 한국어로 변환
  String getBiometricTypeString(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return '얼굴 인식';
      case BiometricType.fingerprint:
        return '지문 인식';
      case BiometricType.iris:
        return '홍채 인식';
      case BiometricType.weak:
        return '기본 보안';
      case BiometricType.strong:
        return '강화된 보안';
    }
  }
}

// 커스텀 예외 클래스
class BiometricException implements Exception {
  final String message;
  BiometricException(this.message);
  
  @override
  String toString() => message;
}