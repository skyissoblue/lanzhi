import 'package:flutter/material.dart';

import '../models/stock.dart';
import 'stock_list_item.dart';

class StockResultList extends StatelessWidget {
  const StockResultList({
    super.key,
    required this.hasConditions,
    required this.stocks,
    required this.onStockTap,
    this.onFavorite,
    this.loading = false,
    this.revision = 0,
  });

  final bool hasConditions;
  final List<Stock> stocks;
  final ValueChanged<Stock> onStockTap;
  final ValueChanged<Stock>? onFavorite;
  final bool loading;
  final int revision;

  @override
  Widget build(BuildContext context) {
    if (!hasConditions) {
      return const Center(
        key: ValueKey('no-stock-list'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: 52, color: Colors.black26),
            SizedBox(height: 12),
            Text('添加查询条件后显示筛选结果', style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }
    if (loading && stocks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (stocks.isEmpty) return const Center(child: Text('没有符合当前条件的股票'));
    return ListView.separated(
      key: ValueKey(revision),
      itemCount: stocks.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) => StockListItem(
        stock: stocks[index],
        onTap: () => onStockTap(stocks[index]),
        onFavorite: onFavorite == null
            ? null
            : () => onFavorite!(stocks[index]),
      ),
    );
  }
}
