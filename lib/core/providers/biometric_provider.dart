// lib/core/providers/biometric_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_service.dart';

// BiometricService Provider
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

// 생체 인증 가용성 상태 Provider
final biometricAvailabilityProvider = FutureProvider<bool>((ref) async {
  final biometricService = ref.watch(biometricServiceProvider);
  return await biometricService.isBiometricAvailable();
});

// 사용 가능한 생체 인증 방법 Provider
final availableBiometricsProvider = FutureProvider<List<BiometricType>>((ref) async {
  final biometricService = ref.watch(biometricServiceProvider);
  return await biometricService.getAvailableBiometrics();
});

// 생체 인증 상태 관리 StateNotifierProvider
final biometricAuthProvider = StateNotifierProvider<BiometricAuthNotifier, BiometricAuthState>((ref) {
  return BiometricAuthNotifier(ref.watch(biometricServiceProvider));
});

class BiometricAuthNotifier extends StateNotifier<BiometricAuthState> {
  final BiometricService _biometricService;
  
  BiometricAuthNotifier(this._biometricService) : super(const BiometricAuthState.initial());
  
  Future<void> authenticate({String? customReason}) async {
    state = const BiometricAuthState.loading();
    
    try {
      final result = await _biometricService.authenticate(
        reason: customReason ?? '앱 보안을 위해 생체 인증을 진행해주세요',
      );
      
      if (result) {
        state = const BiometricAuthState.success();
      } else {
        state = const BiometricAuthState.failure('인증에 실패했습니다');
      }
    } on BiometricException catch (e) {
      state = BiometricAuthState.failure(e.message);
    } catch (e) {
      state = const BiometricAuthState.failure('예상치 못한 오류가 발생했습니다');
    }
  }
  
  void reset() {
    state = const BiometricAuthState.initial();
  }
}

// 생체 인증 상태 클래스
sealed class BiometricAuthState {
  const BiometricAuthState();
  
  bool get isSuccess => this is _Success;
  bool get isLoading => this is _Loading;
  bool get isFailure => this is _Failure;
  String? get errorMessage => this is _Failure ? (this as _Failure).message : null;
  
  const factory BiometricAuthState.initial() = _Initial;
  const factory BiometricAuthState.loading() = _Loading;
  const factory BiometricAuthState.success() = _Success;
  const factory BiometricAuthState.failure(String message) = _Failure;
}

class _Initial extends BiometricAuthState {
  const _Initial();
}

class _Loading extends BiometricAuthState {
  const _Loading();
}

class _Success extends BiometricAuthState {
  const _Success();
}

class _Failure extends BiometricAuthState {
  final String message;
  const _Failure(this.message);
  
  @override
  String toString() => '_Failure(message: $message)';
}