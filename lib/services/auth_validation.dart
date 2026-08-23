String? validatePhone(String? value) {
  if (!RegExp(r'^1\d{10}$').hasMatch(value?.trim() ?? '')) {
    return '请输入正确的11位手机号';
  }
  return null;
}

String? validatePassword(String? value) {
  final length = value?.length ?? 0;
  if (length < 8 || length > 72) return '密码长度必须为8～72位';
  return null;
}

String? validateNickname(String? value) {
  if ((value?.trim().length ?? 0) > 50) return '昵称不能超过50个字符';
  return null;
}
