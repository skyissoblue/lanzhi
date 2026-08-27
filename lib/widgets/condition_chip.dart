import 'package:flutter/material.dart';

import '../models/condition.dart';

class ConditionTag extends StatelessWidget {
  const ConditionTag({super.key, required this.condition, this.onDeleted});

  final Condition condition;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(condition.label),
    onDeleted: onDeleted,
    deleteIcon: const Icon(Icons.close, size: 17),
    backgroundColor: const Color(0xFFFFECEE),
    side: const BorderSide(color: Color(0xFFFFC8CD)),
    labelStyle: const TextStyle(
      color: Color(0xFFF52D3A),
      fontWeight: FontWeight.w600,
    ),
  );
}
