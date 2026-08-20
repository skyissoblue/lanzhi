import 'package:flutter/material.dart';

class IndicatorController extends ChangeNotifier {
  IndicatorController();

  bool _volume = true;
  bool _macd = false;
  bool _kdj = false;
  bool _rsi = false;

  bool get volume => _volume;
  bool get macd => _macd;
  bool get kdj => _kdj;
  bool get rsi => _rsi;

  void setVolume(bool value) {
    if (_volume == value) return;
    _volume = value;
    notifyListeners();
  }

  void setMacd(bool value) {
    if (_macd == value) return;
    _macd = value;
    notifyListeners();
  }

  void setKdj(bool value) {
    if (_kdj == value) return;
    _kdj = value;
    notifyListeners();
  }

  void setRsi(bool value) {
    if (_rsi == value) return;
    _rsi = value;
    notifyListeners();
  }
}

class IndicatorPanel extends StatelessWidget {
  const IndicatorPanel({super.key, required this.controller});

  final IndicatorController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Material(
      color: Colors.white,
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        children: [
          _switch('成交量', controller.volume, controller.setVolume),
          _switch('MACD', controller.macd, controller.setMacd),
          _switch('KDJ', controller.kdj, controller.setKdj),
          _switch('RSI', controller.rsi, controller.setRsi),
        ],
      ),
    ),
  );

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) =>
      Semantics(
        label: '$label指标开关',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            Switch(
              key: ValueKey('indicator-$label'),
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      );
}
