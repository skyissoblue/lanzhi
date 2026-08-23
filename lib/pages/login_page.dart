import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final phone = TextEditingController(),
      password = TextEditingController(),
      nickname = TextEditingController();
  bool register = false;
  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    nickname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.auto_graph,
                    size: 72,
                    color: Color(0xFF126B4D),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    register ? '注册澜知选股' : '登录澜知选股',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: '手机号',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (register) ...[
                    TextField(
                      controller: nickname,
                      decoration: const InputDecoration(
                        labelText: '昵称',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '密码（至少8位）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (auth.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        auth.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: auth.loading
                        ? null
                        : () => ref
                              .read(authProvider.notifier)
                              .login(
                                phone.text.trim(),
                                password.text,
                                nickname: nickname.text.trim(),
                                register: register,
                              ),
                    child: auth.loading
                        ? const CircularProgressIndicator()
                        : Text(register ? '注册并登录' : '登录'),
                  ),
                  TextButton(
                    onPressed: auth.loading
                        ? null
                        : () => setState(() => register = !register),
                    child: Text(register ? '已有账号？登录' : '没有账号？注册'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
