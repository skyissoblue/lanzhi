import 'package:flutter/material.dart';

import '../models/stock.dart';

class StockListItem extends StatelessWidget {
  const StockListItem({
    super.key,
    required this.stock,
    this.onTap,
    this.onFavorite,
  });

  final Stock stock;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: CircleAvatar(
      backgroundColor: const Color(0xFFE8F3EE),
      foregroundColor: const Color(0xFF126B4D),
      child: Text(stock.name.isEmpty ? '?' : stock.name.substring(0, 1)),
    ),
    title: Text(
      stock.name,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      [
        stock.code,
        stock.industry,
        stock.board,
      ].whereType<String>().where((text) => text.isNotEmpty).join(' · '),
    ),
    trailing: onFavorite == null
        ? const Icon(Icons.chevron_right)
        : IconButton(
            icon: const Icon(Icons.star_border),
            tooltip: '加入自选',
            onPressed: onFavorite,
          ),
  );
}
