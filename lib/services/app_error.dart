import 'package:dio/dio.dart';

String friendlyErrorMessage(Object error) {
  if (error is! DioException) return '操作失败，请稍后重试';

  final status = error.response?.statusCode;
  final detail = error.response?.data is Map
      ? (error.response?.data as Map)['detail']
      : null;
  if (status == 422) {
    if (detail is List) {
      final fields = detail
          .whereType<Map>()
          .expand((item) => (item['loc'] as List? ?? const []))
          .map((item) => item.toString())
          .toSet();
      if (fields.contains('phone')) return '请输入正确的11位手机号';
      if (fields.contains('password')) return '密码长度必须为8～72位';
      if (fields.contains('nickname')) return '昵称不能超过50个字符';
    }
    return '输入内容不符合要求，请检查后重试';
  }
  if (status == 409) return '该手机号已经注册，请直接登录';
  if (status == 401) return '手机号或密码错误';
  if (status == 404) return '请求的内容不存在';
  if (status != null && status >= 500) return '服务器暂时繁忙，请稍后重试';
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return '连接超时，请检查网络后重试';
  }
  if (error.type == DioExceptionType.connectionError) {
    return '无法连接服务器，请检查网络后重试';
  }
  return '请求失败，请稍后重试';
}
