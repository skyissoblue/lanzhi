import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_stock_picker/pages/kline_page.dart';
import 'package:voice_stock_picker/widgets/indicator_panel.dart';

void main() {
  testWidgets('K线页面渲染示例数据和默认成交量', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: KlinePage(stockCode: '000001', stockName: '平安银行'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('kline-chart')), findsOneWidget);
    expect(find.textContaining('000001'), findsOneWidget);
    final volume = tester.widget<Switch>(
      find.byKey(const ValueKey('indicator-成交量')),
    );
    expect(volume.value, isTrue);
  });

  testWidgets('指标开关可同时启用 MACD KDJ RSI', (tester) async {
    final controller = IndicatorController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: IndicatorPanel(controller: controller)),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('indicator-MACD')));
    await tester.tap(find.byKey(const ValueKey('indicator-KDJ')));
    await tester.tap(find.byKey(const ValueKey('indicator-RSI')));
    await tester.pump();

    expect(controller.macd, isTrue);
    expect(controller.kdj, isTrue);
    expect(controller.rsi, isTrue);
    controller.dispose();
  });
}
