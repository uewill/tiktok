import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class CadenceDetector {
  static const double _alpha = 0.85;
  static const double _stepThreshold = 1.15;
  static const int _minStepMs = 220;

  final Queue<DateTime> _stepTimes = Queue<DateTime>();

  StreamSubscription<AccelerometerEvent>? _sub;
  double _gravity = 9.8;
  DateTime? _lastStepAt;

  void start(void Function(int spm) onCadence) {
    _sub?.cancel();
    _sub = accelerometerEventStream().listen((AccelerometerEvent e) {
      final double mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      _gravity = _alpha * _gravity + (1 - _alpha) * mag;
      final double linear = mag - _gravity;

      final DateTime now = DateTime.now();
      if (linear > _stepThreshold) {
        if (_lastStepAt == null || now.difference(_lastStepAt!).inMilliseconds > _minStepMs) {
          _lastStepAt = now;
          _stepTimes.addLast(now);
          while (_stepTimes.isNotEmpty &&
              now.difference(_stepTimes.first).inSeconds > 12) {
            _stepTimes.removeFirst();
          }

          if (_stepTimes.length >= 2) {
            final int spanMs =
                _stepTimes.last.difference(_stepTimes.first).inMilliseconds;
            if (spanMs > 0) {
              final double stepsPerMin =
                  (_stepTimes.length - 1) * 60000 / spanMs;
              onCadence(stepsPerMin.round().clamp(60, 230));
            }
          }
        }
      }
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void dispose() {
    stop();
  }
}
