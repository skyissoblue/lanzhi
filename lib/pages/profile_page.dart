import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/selection_combo.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key, required this.onOpenCombo});
  final ValueChanged<String> onOpenCombo;
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late Future<List<SelectionCombo>> favorites;
  @override
  void initState() {
    super.initState();
    favorites = ApiService().getFavoriteSessions();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final phone = '${auth.user?['phone'] ?? ''}';
    final masked = phone.length == 11
        ? '${phone.substring(0, 3)}****${phone.substring(7)}'
        : phone;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 38)),
        const SizedBox(height: 12),
        Text(
          '${auth.user?['nickname'] ?? '澜知用户'}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(masked, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Text('我的收藏组合', style: Theme.of(context).textTheme.titleMedium),
        FutureBuilder<List<SelectionCombo>>(
          future: favorites,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) return Text('加载失败：${snapshot.error}');
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('还没有收藏组合'),
              );
            }
            return Column(
              children: [
                for (final combo in items)
                  ListTile(
                    leading: const Icon(Icons.bookmark),
                    title: Text(combo.name),
                    subtitle: Text('${combo.currentCount} 只'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => widget.onOpenCombo(combo.sessionId),
                  ),
              ],
            );
          },
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.settings_outlined),
          title: Text('设置'),
          trailing: Icon(Icons.chevron_right),
        ),
        OutlinedButton.icon(
          onPressed: () => ref.read(authProvider.notifier).logout(),
          icon: const Icon(Icons.logout),
          label: const Text('退出登录'),
        ),
      ],
    );
  }
}
