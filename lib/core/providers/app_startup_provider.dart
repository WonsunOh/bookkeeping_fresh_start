// lib/core/providers/app_startup_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'biometric_provider.dart';

// 앱 시작 시 생체 인증 필요 여부를 체크하는 Provider
final shouldShowBiometricProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

  debugPrint('Biometric enabled in settings: $biometricEnabled');
  
  if (!biometricEnabled) {
    debugPrint('Biometric disabled, skipping auth');
    // return false; // 생체 인증이 비활성화된 경우
    // 테스트용: 항상 true 반환
  return true;
  }
  
  // 생체 인증이 활성화된 경우, 기기에서 사용 가능한지 확인
  final biometricService = ref.watch(biometricServiceProvider);
  final isAvailable = await biometricService.isBiometricAvailable();
  
  debugPrint('Biometric available: $isAvailable');
  return isAvailable;
});

// 앱의 인증 상태를 관리하는 Provider
final appAuthStateProvider = StateNotifierProvider<AppAuthStateNotifier, AppAuthState>((ref) {
  return AppAuthStateNotifier();
});

class AppAuthStateNotifier extends StateNotifier<AppAuthState> {
  AppAuthStateNotifier() : super(AppAuthState.checking);
  
  void setAuthenticated() {
    state = AppAuthState.authenticated;
  }
  
  void setUnauthenticated() {
    state = AppAuthState.unauthenticated;
  }
  
  void setBiometricRequired() {
    state = AppAuthState.biometricRequired;
  }
}

enum AppAuthState {
  checking,      // 인증 상태 확인 중
  authenticated, // 인증 완료
  unauthenticated, // 미인증
  biometricRequired, // 생체 인증 필요
}