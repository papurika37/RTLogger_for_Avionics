import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/view/home_page.dart'; // 作成したHomePageをインポート

void main() {
  runApp(
    // アプリ全体をProviderScopeでラップ
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Serial CSV Logger (Riverpod)',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // ホーム画面としてHomePageを指定
      home: const HomePage(),
    );
  }
}