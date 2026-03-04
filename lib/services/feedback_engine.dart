import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

import 'metronome_controller.dart';

class FeedbackEngine {
  Timer? _beatTimer;
  int _beatCount = 0;
  final FlutterTts _tts = FlutterTts();

  Future<void> configureTts() async {
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  void start({
    required int spm,
    required Set<FeedbackType> types,
  }) {
    stop();
    final int ms = (60000 / spm).round().clamp(120, 2000);
    _beatTimer = Timer.periodic(Duration(milliseconds: ms), (_) async {
      _beatCount++;
      if (types.contains(FeedbackType.audio)) {
        SystemSound.play(SystemSoundType.click);
      }
      if (types.contains(FeedbackType.vibration) && await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 24, amplitude: 100);
      }
      if (types.contains(FeedbackType.voiceCount) && _beatCount.isEven) {
        final String text = ((_beatCount ~/ 2) % 2 == 1) ? '1' : '2';
        _tts.speak(text);
      }
    });
  }

  void updateTempo({required int spm, required Set<FeedbackType> types}) {
    start(spm: spm, types: types);
  }

  void stop() {
    _beatTimer?.cancel();
    _beatTimer = null;
    _beatCount = 0;
    _tts.stop();
  }

  void dispose() {
    stop();
  }
}
