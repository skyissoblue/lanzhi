import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';

class VoiceStockPickerApp extends ConsumerStatefulWidget {
  const VoiceStockPickerApp({super.key});
  @override
  ConsumerState<VoiceStockPickerApp> createState() => _AppState();
}

class _AppState extends ConsumerState<VoiceStockPickerApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).initialize());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return MaterialApp(
      title: '澜知选股',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF52D3A),
          primary: const Color(0xFFF52D3A),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF52D3A),
          foregroundColor: Colors.white,
          surfaceTintColor: Color(0xFFF52D3A),
          centerTitle: true,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFFFE5E7),
          iconTheme: WidgetStatePropertyAll(
            IconThemeData(color: Color(0xFFF52D3A)),
          ),
        ),
        useMaterial3: true,
      ),
      home: !auth.ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : auth.loggedIn
          ? const HomePage()
          : const LoginPage(),
    );
  }
}
