import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});
  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final api = ApiService();
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = api.groupedWatchlist();
  }

  void reload() => setState(() => future = api.groupedWatchlist());
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('加载失败：${snapshot.error}'));
      }
      final groups = snapshot.data ?? [];
      if (groups.isEmpty) return const Center(child: Text('还没有自选股，去首页选股后加入吧'));
      return ListView(
        children: [
          for (final group in groups)
            ExpansionTile(
              initiallyExpanded: true,
              title: Text('来自：${group['combo_name']}'),
              children: [
                for (final stock in (group['stocks'] as List? ?? const []))
                  ListTile(
                    title: Text('${stock['name'] ?? ''}'),
                    subtitle: Text('${stock['code']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await api.removeWatchlist('${stock['code']}');
                        reload();
                      },
                    ),
                  ),
              ],
            ),
        ],
      );
    },
  );
}
