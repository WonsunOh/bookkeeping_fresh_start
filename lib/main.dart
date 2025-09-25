import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/repeating_transactions/services/repeating_transaction_service.dart';
import 'firebase_options.dart'; // flutterfire_cli가 생성한 파일
import 'core/router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main()async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('ko_KR', null);
  } catch (e) {
    debugPrint('날짜 형식 초기화 실패: $e');
  }


  // 웹 환경에서 디버그 에러 억제
  if (kIsWeb && kDebugMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('EngineFlutterView') ||
          details.exception.toString().contains('DebugService')) {
        // 웹 환경 특정 에러는 무시
        return;
      }
      FlutterError.presentError(details);
    };
  }
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final container = ProviderContainer();
  try {
    await container.read(appStartupProvider.future);
  } catch (e) {
    debugPrint('앱 초기화 서비스 실패: $e');
  }

  runApp(
    // 4. 앱의 나머지 부분에서 사용할 수 있도록 UncontrolledProviderScope를 사용합니다.
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      routerConfig: router,
      title: '복식부기 장부',
      
      // 💡 로케일 설정 - 한국어를 기본으로 설정
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어
        Locale('en', 'US'), // 영어 (fallback)
      ],
      
      // 💡 MaterialLocalizations 델리게이트 추가 - 이 부분이 가장 중요합니다!
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
}