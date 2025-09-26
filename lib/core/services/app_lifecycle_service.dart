// lib/core/services/app_lifecycle_service.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_startup_provider.dart';

class AppLifecycleService with WidgetsBindingObserver {
  final Ref _ref;
  DateTime? _pausedTime;
  bool _wasInBackground = false;
  // static const int _requireAuthAfterMinutes = 1; // 5분 후 재인증 요구
  static const int _requireAuthAfterSeconds = 300;

  AppLifecycleService(this._ref) {
    WidgetsBinding.instance.addObserver(this);
  }

 

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle changed: $state');
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (!_wasInBackground) {
          _pausedTime = DateTime.now();
          _wasInBackground = true;
          debugPrint('App went to background at: $_pausedTime');
        }
        break;

      case AppLifecycleState.resumed:
       if (_wasInBackground) {
          debugPrint('App came to foreground, checking time...');
          _handleAppResumed();
          _wasInBackground = false;
        }
        break;

      default:
        break;
    }
  }

  Future<void> _handleAppResumed() async {
    debugPrint('_handleAppResumed called');

    if (_pausedTime == null) {
      debugPrint('_pausedTime is null, returning');
      return;
    }

    final now = DateTime.now();
    // final difference = now.difference(_pausedTime!).inMinutes;
    final difference = now.difference(_pausedTime!).inSeconds;

    debugPrint('Background time: $_pausedTime');
    debugPrint('Foreground time: $now');
    debugPrint('Time difference: $difference seconds');

    // 설정된 시간이 지나면 재인증 요구
    // if (difference >= _requireAuthAfterMinutes) {
    if (difference >= _requireAuthAfterSeconds) {
      debugPrint('Time exceeded, requiring biometric authentication');
      _ref.read(appAuthStateProvider.notifier).setBiometricRequired();
    } else {
      debugPrint('Time not exceeded, no re-authentication needed');
    }
    
    _pausedTime = null;
  }
   void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

// AppLifecycleService Provider
final appLifecycleServiceProvider = Provider<AppLifecycleService>((ref) {
  final service = AppLifecycleService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
