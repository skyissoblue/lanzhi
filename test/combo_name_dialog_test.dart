import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_stock_picker/pages/home_page.dart';

void main() {
  testWidgets('组合改名弹窗关闭后不会提前销毁输入框依赖', (tester) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showComboNameDialog(context, '重命名组合', '组合1');
              },
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '我的组合');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(result, '我的组合');
    expect(tester.takeException(), isNull);
  });
}
