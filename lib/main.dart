import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/repeating_transactions/services/repeating_transaction_service.dart';
import 'firebase_options.dart'; // flutterfire_cli가 생성한 파일
import 'core/router.dart';

void main()async {
  // Flutter 엔진과 위젯 트리를 바인딩합니다.
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase를 초기화합니다.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

 // 2. Provider를 사용하기 위해 ProviderContainer를 생성합니다.
  final container = ProviderContainer();
  // 3. 앱이 시작될 때 반복 거래 처리 로직을 실행합니다.
  await container.read(appStartupProvider.future);
  
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

    return MaterialApp.router(
      routerConfig: router, // 여기에 router 설정을 연결합니다.
      title: '복식부기 장부',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
