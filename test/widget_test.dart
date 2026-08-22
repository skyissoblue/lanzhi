import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_stock_picker/models/condition.dart';
import 'package:voice_stock_picker/models/stock.dart';
import 'package:voice_stock_picker/widgets/condition_chip.dart';
import 'package:voice_stock_picker/widgets/stock_list_item.dart';
import 'package:voice_stock_picker/widgets/stock_result_list.dart';

void main() {
  testWidgets('条件标签显示并响应删除', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConditionTag(
            condition: const Condition(type: 'industry', value: '科技'),
            onDeleted: () => deleted = true,
          ),
        ),
      ),
    );
    expect(find.text('行业 科技'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    expect(deleted, isTrue);
  });

  testWidgets('股票列表项渲染名称和代码', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StockListItem(
            stock: Stock(code: '688041', name: '海光信息', industry: '科技'),
          ),
        ),
      ),
    );
    expect(find.text('海光信息'), findsOneWidget);
    expect(find.text('688041 · 科技'), findsOneWidget);
  });

  testWidgets('没有查询条件时不显示股票列表', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockResultList(
            hasConditions: false,
            stocks: const [Stock(code: '000001', name: '平安银行')],
            onStockTap: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('添加查询条件后显示筛选结果'), findsOneWidget);
    expect(find.byType(StockListItem), findsNothing);
  });
}
