import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_stock_picker/services/api_service.dart';
import 'package:voice_stock_picker/services/app_error.dart';
import 'package:voice_stock_picker/services/auth_validation.dart';
import 'package:voice_stock_picker/models/selection_combo.dart';

void main() {
  test('keeps stock and ETF combinations in separate universes', () {
    final stock = SelectionCombo.fromJson({
      'combo_id': 1,
      'name': '股票组合',
      'asset_type': 'stock',
    });
    final etf = SelectionCombo.fromJson({
      'combo_id': 2,
      'name': 'ETF组合',
      'asset_type': 'etf',
    });

    expect(stock.assetType, 'stock');
    expect(etf.assetType, 'etf');
  });

  test('validates registration fields before sending', () {
    expect(validatePhone('1378892145'), '请输入正确的11位手机号');
    expect(validatePhone('13788921456'), isNull);
    expect(validatePassword('1234567'), '密码长度必须为8～72位');
    expect(validatePassword('12345678'), isNull);
  });

  test('turns backend validation errors into friendly Chinese messages', () {
    final options = RequestOptions(path: '/api/auth/register');
    final error = DioException(
      requestOptions: options,
      response: Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 422,
        data: const {
          'detail': [
            {
              'loc': ['body', 'phone'],
              'msg': 'String should match pattern',
            },
          ],
        },
      ),
    );
    expect(friendlyErrorMessage(error), '请输入正确的11位手机号');
  });

  test('recognizes an expired backend session', () {
    final options = RequestOptions(path: '/api/session/expired/stocks');
    final error = DioException(
      requestOptions: options,
      response: Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 404,
        data: const {'detail': 'session not found'},
      ),
    );

    expect(ApiService(dio: Dio()).isSessionMissing(error), isTrue);
  });

  test('parses every condition returned by multi-condition NLU', () {
    final result = StepResult.fromJson({
      'before': 100,
      'after': 12,
      'removed': 88,
      'stocks': const [],
      'action': 'add',
      'applied_conditions': [
        {'type': 'exclude_st'},
        {
          'type': 'factor',
          'name': 'roe',
          'op': '>',
          'value': 15,
          'period': 'ttm',
        },
      ],
    });

    expect(result.appliedConditions, hasLength(2));
    expect(result.appliedConditions!.last.name, 'roe');
    expect(result.appliedConditions!.last.extra['period'], 'ttm');
  });

  test('renders monthly and yearly condition labels', () {
    final monthly = StepResult.fromJson({
      'condition': {
        'type': 'ma_cross',
        'period': 'monthly',
        'ma': 5,
        'op': '>=',
      },
    }).condition!;
    final yearly = StepResult.fromJson({
      'condition': {
        'type': 'ma_deviation',
        'period': 'yearly',
        'ma': 10,
        'max_pct': 8,
      },
    }).condition!;

    expect(monthly.label, contains('月线'));
    expect(yearly.label, contains('年线'));
  });
}
