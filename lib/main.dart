import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/home_page.dart';

void main() => runApp(const ProviderScope(child: VoiceStockPickerApp()));

class VoiceStockPickerApp extends StatelessWidget {
  const VoiceStockPickerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '澜知选股',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF126B4D)),
      useMaterial3: true,
    ),
    home: const HomePage(),
  );
}
