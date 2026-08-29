import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_stock_picker/pages/kline_page.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:voice_stock_picker/widgets/indicator_panel.dart';

void main() {
  double chartScale(WidgetTester tester) {
    final paints = tester.widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(KChartWidget),
        matching: find.byType(CustomPaint),
      ),
    );
    final chart = paints.firstWhere(
      (paint) => paint.painter.runtimeType.toString() == 'ChartPainter',
    );
    return (chart.painter as dynamic).scaleX as double;
  }

  Future<void> pinch(
    WidgetTester tester, {
    required Offset firstStart,
    required Offset secondStart,
    required Offset firstEnd,
    required Offset secondEnd,
  }) async {
    final first = await tester.startGesture(firstStart, pointer: 1);
    final second = await tester.startGesture(secondStart, pointer: 2);
    await tester.pump();
    await first.moveTo(firstEnd);
    await second.moveTo(secondEnd);
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();
  }

  testWidgets('K线页面渲染示例数据和默认成交量', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: KlinePage(stockCode: '000001', stockName: '平安银行'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('kline-chart-daily')), findsOneWidget);
    final chart = tester.widget<KChartWidget>(find.byType(KChartWidget));
    expect(chart.minScaleX, 0.12);
    expect(chart.maxScaleX, 3.0);
    expect(find.textContaining('000001'), findsOneWidget);
    final volume = tester.widget<Switch>(
      find.byKey(const ValueKey('indicator-成交量')),
    );
    expect(volume.value, isTrue);
  });

  testWidgets('K线支持日周月年周期切换', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: KlinePage(stockCode: '000001')),
    );
    await tester.pumpAndSettle();

    expect(find.text('日K'), findsOneWidget);
    expect(find.text('周K'), findsOneWidget);
    expect(find.text('月K'), findsOneWidget);
    expect(find.text('年K'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('period-monthly')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kline-chart-monthly')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('period-yearly')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kline-chart-yearly')), findsOneWidget);
  });

  testWidgets('任意方向向内缩小、向外放大且不依赖焦点', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: KlinePage(stockCode: '000001')),
    );
    await tester.pumpAndSettle();

    final rect = tester.getRect(
      find.byKey(const ValueKey('kline-chart-daily')),
    );
    final center = rect.center;

    await pinch(
      tester,
      firstStart: center - const Offset(100, 0),
      secondStart: center + const Offset(100, 0),
      firstEnd: center - const Offset(30, 0),
      secondEnd: center + const Offset(30, 0),
    );
    final afterHorizontalPinchIn = chartScale(tester);
    expect(afterHorizontalPinchIn, lessThan(1.0));

    await pinch(
      tester,
      firstStart: center - const Offset(0, 30),
      secondStart: center + const Offset(0, 30),
      firstEnd: center - const Offset(0, 90),
      secondEnd: center + const Offset(0, 90),
    );
    expect(chartScale(tester), greaterThan(afterHorizontalPinchIn));
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
