import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_stock_picker/services/api_service.dart';

void main() {
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
}
