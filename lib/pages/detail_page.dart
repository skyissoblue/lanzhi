import 'package:flutter/material.dart';

import '../models/stock.dart';
import 'kline_page.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(stock.name)),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(stock.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(stock.code),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    KlinePage(stockCode: stock.code, stockName: stock.name),
              ),
            ),
            icon: const Icon(Icons.candlestick_chart),
            label: const Text('查看 K 线与技术指标'),
          ),
        ],
      ),
    ),
  );
}
