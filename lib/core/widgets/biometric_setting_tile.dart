// lib/features/settings/widgets/biometric_setting_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/biometric_provider.dart';

// SharedPreferences에서 생체 인증 설정을 관리하는 Provider
final biometricSettingsProvider = StateNotifierProvider<BiometricSettingsNotifier, bool>((ref) {
  return BiometricSettingsNotifier();
});

class BiometricSettingsNotifier extends StateNotifier<bool> {
  BiometricSettingsNotifier() : super(false) {
    _loadSetting();
  }
  
  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('biometric_enabled') ?? false;
  }
  
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
    state = enabled;
  }
}

class BiometricSettingTile extends ConsumerWidget {
  const BiometricSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricAvailable = ref.watch(biometricAvailabilityProvider);
    final availableBiometrics = ref.watch(availableBiometricsProvider);
    final biometricEnabled = ref.watch(biometricSettingsProvider);
    
    return biometricAvailable.when(
      data: (isAvailable) {
        if (!isAvailable) {
          return ListTile(
            leading: const Icon(Icons.security, color: Colors.grey),
            title: const Text('생체 인증'),
            subtitle: const Text('사용할 수 없음'),
            trailing: Switch(
              value: false,
              onChanged: null, // 비활성화
            ),
          );
        }
        
        return availableBiometrics.when(
          data: (biometrics) {
            final hasFingerprint = biometrics.contains(BiometricType.fingerprint);
            final hasFace = biometrics.contains(BiometricType.face);
            
            String subtitle = '';
            IconData leadingIcon = Icons.security;
            
            if (hasFingerprint && hasFace) {
              subtitle = '지문 및 얼굴 인식 사용 가능';
              leadingIcon = Icons.fingerprint;
            } else if (hasFingerprint) {
              subtitle = '지문 인식 사용 가능';
              leadingIcon = Icons.fingerprint;
            } else if (hasFace) {
              subtitle = '얼굴 인식 사용 가능';
              leadingIcon = Icons.face;
            } else {
              subtitle = '생체 인증 사용 가능';
            }
            
            return ListTile(
              leading: Icon(leadingIcon),
              title: const Text('생체 인증'),
              subtitle: Text(subtitle),
              trailing: Switch(
                value: biometricEnabled,
                onChanged: (value) async {
                  if (value) {
                    // 생체 인증을 활성화하기 전에 한 번 테스트
                    final biometricService = ref.read(biometricServiceProvider);
                    try {
                      final result = await biometricService.authenticate(
                        reason: '생체 인증을 활성화하기 위해 인증해주세요',
                      );
                      
                      if (result) {
                        ref.read(biometricSettingsProvider.notifier).setBiometricEnabled(true);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('생체 인증이 활성화되었습니다')),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('인증 실패: $e')),
                        );
                      }
                    }
                  } else {
                    ref.read(biometricSettingsProvider.notifier).setBiometricEnabled(false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('생체 인증이 비활성화되었습니다')),
                      );
                    }
                  }
                },
              ),
            );
          },
          loading: () => ListTile(
            leading: const Icon(Icons.security),
            title: const Text('생체 인증'),
            subtitle: const Text('확인 중...'),
            trailing: Switch(
              value: biometricEnabled,
              onChanged: null,
            ),
          ),
          error: (error, _) => ListTile(
            leading: const Icon(Icons.security, color: Colors.grey),
            title: const Text('생체 인증'),
            subtitle: const Text('오류 발생'),
            trailing: Switch(
              value: false,
              onChanged: null,
            ),
          ),
        );
      },
      loading: () => ListTile(
        leading: const Icon(Icons.security),
        title: const Text('생체 인증'),
        subtitle: const Text('확인 중...'),
        trailing: Switch(
          value: biometricEnabled,
          onChanged: null,
        ),
      ),
      error: (error, _) => ListTile(
        leading: const Icon(Icons.security, color: Colors.grey),
        title: const Text('생체 인증'),
        subtitle: const Text('사용할 수 없음'),
        trailing: Switch(
          value: false,
          onChanged: null,
        ),
      ),
    );
  }
}