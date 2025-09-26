// lib/features/auth/screens/biometric_auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/providers/app_startup_provider.dart';
import '../../../core/providers/biometric_provider.dart';

class BiometricAuthScreen extends ConsumerStatefulWidget {
  final VoidCallback? onAuthenticationSuccess;
  
  const BiometricAuthScreen({
    super.key,
    this.onAuthenticationSuccess,
  });

  @override
  ConsumerState<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends ConsumerState<BiometricAuthScreen> {
  @override
  void initState() {
    super.initState();
    // 화면이 로드되면 자동으로 생체 인증 시도
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateUser();
    });
  }

  Future<void> _authenticateUser() async {
    final authNotifier = ref.read(biometricAuthProvider.notifier);
    await authNotifier.authenticate();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(biometricAuthProvider);
    final availableBiometrics = ref.watch(availableBiometricsProvider);

    // 인증 성공 시 콜백 실행
    ref.listen<BiometricAuthState>(biometricAuthProvider, (previous, next) {
      debugPrint('Auth state: ${next.runtimeType}, isSuccess: ${next.isSuccess}');
  
  if (next.isSuccess) {
   debugPrint('Authentication successful, navigating to main app...');
    // 직접 상태 변경
    ref.read(appAuthStateProvider.notifier).setAuthenticated();
  }
});

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 앱 아이콘 또는 로고
                Icon(
                  Icons.security_rounded,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 32),
                
                // 앱 이름
                Text(
                  '가계부',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 48),
                
                // 생체 인증 아이콘 및 메시지
                availableBiometrics.when(
                  data: (biometrics) {
                    if (biometrics.isEmpty) {
                      return Column(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '생체 인증을 사용할 수 없습니다',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    }
                    
                    final hasFingerprint = biometrics.contains(BiometricType.fingerprint);
                    final hasFace = biometrics.contains(BiometricType.face);
                    
                    IconData biometricIcon = Icons.fingerprint;
                    String biometricText = '지문으로 인증하기';
                    
                    if (hasFace) {
                      biometricIcon = Icons.face;
                      biometricText = '얼굴로 인증하기';
                    }
                    
                    return Column(
                      children: [
                        Icon(
                          biometricIcon,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          biometricText,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '생체 인증을 확인할 수 없습니다',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // 인증 상태에 따른 UI
                _buildAuthStateUI(context, authState),
                
                const SizedBox(height: 24),
                
                // 대체 로그인 방법 (필요한 경우)
                TextButton(
                  onPressed: () {
                    // 패스워드나 PIN으로 로그인하는 화면으로 이동
                    // context.go('/password-login');
                  },
                  child: const Text('다른 방법으로 로그인'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthStateUI(BuildContext context, BiometricAuthState authState) {
    // 로딩 상태 체크
    if (authState.runtimeType.toString() == '_Loading') {
      return const CircularProgressIndicator();
    }
    
    // 실패 상태 체크
    if (authState.runtimeType.toString() == '_Failure') {
      String errorMessage = '인증에 실패했습니다';
      
      // _Failure 클래스에서 메시지 추출 (reflection 대신 toString 사용)
      final stateString = authState.toString();
      if (stateString.contains('message:')) {
        try {
          final startIndex = stateString.indexOf('message:') + 8;
          final endIndex = stateString.indexOf(')', startIndex);
          if (endIndex > startIndex) {
            errorMessage = stateString.substring(startIndex, endIndex).trim();
          }
        } catch (e) {
          // toString 파싱 실패 시 기본 메시지 사용
        }
      }
      
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _authenticateUser,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ),
        ],
      );
    }
    
    // 기본 상태 (초기 상태)
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _authenticateUser,
        icon: const Icon(Icons.security),
        label: const Text('인증하기'),
      ),
    );
  }
}