import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/run_session.dart';
import 'background_runtime.dart';
import 'cadence_detector.dart';
import 'feedback_engine.dart';
import 'session_repository.dart';

enum FeedbackType { audio, vibration, voiceCount }

class MetronomeController extends ChangeNotifier {
  MetronomeController({
    required SessionRepository repository,
    CadenceDetector? detector,
    FeedbackEngine? feedbackEngine,
    BackgroundRuntime? backgroundRuntime,
  })  : _repository = repository,
        _detector = detector ?? CadenceDetector(),
        _feedbackEngine = feedbackEngine ?? FeedbackEngine(),
        _backgroundRuntime = backgroundRuntime ?? BackgroundRuntime();

  static const int minSpm = 30;
  static const int maxSpm = 250;

  final SessionRepository _repository;
  final CadenceDetector _detector;
  final FeedbackEngine _feedbackEngine;
  final BackgroundRuntime _backgroundRuntime;

  int _targetSpm = 180;
  int _currentSpm = 176;
  bool _running = false;
  bool _adaptiveEnabled = true;
  bool _slopeAdaptiveEnabled = false;
  double _slopePercent = 0;
  DateTime? _startTime;
  TrainingMode _mode = TrainingMode.easy;

  final Set<FeedbackType> _feedback = <FeedbackType>{FeedbackType.audio};
  final List<int> _spmSeries = <int>[];
  final List<int> _targetSeries = <int>[];

  Timer? _tickTimer;
  final Random _random = Random();

  int get targetSpm => _targetSpm;
  int get currentSpm => _currentSpm;
  bool get running => _running;
  bool get adaptiveEnabled => _adaptiveEnabled;
  bool get slopeAdaptiveEnabled => _slopeAdaptiveEnabled;
  double get slopePercent => _slopePercent;
  bool get keepScreenOn => _backgroundRuntime.enabled;
  DateTime? get startTime => _startTime;
  TrainingMode get mode => _mode;
  Set<FeedbackType> get feedback => Set<FeedbackType>.unmodifiable(_feedback);
  List<int> get spmSeries => List<int>.unmodifiable(_spmSeries);
  List<int> get targetSeries => List<int>.unmodifiable(_targetSeries);
  List<RunSession> get history => _repository.all();
  double get weeklyAvg => _repository.weeklyAvgSpm();
  double get monthlyAvg => _repository.monthlyAvgSpm();

  static Future<MetronomeController> create() async {
    final SessionRepository repository = SessionRepository();
    await repository.init();
    final FeedbackEngine engine = FeedbackEngine();
    await engine.configureTts();
    return MetronomeController(repository: repository, feedbackEngine: engine);
  }

  void setMode(TrainingMode mode) {
    _mode = mode;
    switch (mode) {
      case TrainingMode.easy:
        setTargetSpm(170);
      case TrainingMode.tempo:
        setTargetSpm(180);
      case TrainingMode.interval:
        setTargetSpm(188);
      case TrainingMode.race:
        setTargetSpm(184);
    }
    notifyListeners();
  }

  void setTargetSpm(int value) {
    _targetSpm = value.clamp(minSpm, maxSpm);
    if (_running) {
      _feedbackEngine.updateTempo(spm: _targetSpm, types: _feedback);
    }
    notifyListeners();
  }

  int recommendSpmByPace({required int minPerKm, required int secPerKm}) {
    final double pace = minPerKm + secPerKm / 60;
    final double delta = (5.5 - pace) * 6;
    return (180 + delta).round().clamp(165, 195);
  }

  void setSlope(double value) {
    _slopePercent = value.clamp(-15, 15);
    notifyListeners();
  }

  void toggleAdaptive(bool enabled) {
    _adaptiveEnabled = enabled;
    notifyListeners();
  }

  void toggleSlopeAdaptive(bool enabled) {
    _slopeAdaptiveEnabled = enabled;
    notifyListeners();
  }

  void toggleKeepScreenOn(bool enabled) {
    if (enabled) {
      _backgroundRuntime.enable();
    } else {
      _backgroundRuntime.disable();
    }
    notifyListeners();
  }

  void toggleFeedback(FeedbackType type) {
    if (_feedback.contains(type)) {
      _feedback.remove(type);
    } else {
      _feedback.add(type);
    }
    if (_running) {
      _feedbackEngine.updateTempo(spm: _targetSpm, types: _feedback);
    }
    notifyListeners();
  }

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _startTime = DateTime.now();
    _spmSeries.clear();
    _targetSeries.clear();

    _feedbackEngine.start(spm: _targetSpm, types: _feedback);
    _detector.start((int spm) {
      _currentSpm = spm;
    });

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void pause() {
    _running = false;
    _tickTimer?.cancel();
    _tickTimer = null;
    _feedbackEngine.stop();
    _detector.stop();
    notifyListeners();
  }

  Future<void> stopAndSave() async {
    if (_startTime == null || _spmSeries.isEmpty) {
      pause();
      return;
    }

    final DateTime end = DateTime.now();
    final double avg = _spmSeries.reduce((int a, int b) => a + b) / _spmSeries.length;
    final double variance = _spmSeries
            .map((int v) => pow(v - avg, 2).toDouble())
            .reduce((double a, double b) => a + b) /
        _spmSeries.length;
    int onTarget = 0;
    for (int i = 0; i < _spmSeries.length; i++) {
      if ((_spmSeries[i] - _targetSeries[i]).abs() <= 5) {
        onTarget++;
      }
    }

    await _repository.add(
      RunSession(
        startTime: _startTime!,
        endTime: end,
        targetSpm: _targetSpm,
        avgSpm: avg,
        stability: sqrt(variance),
        adherence: onTarget / _spmSeries.length,
        mode: _mode,
        spms: List<int>.from(_spmSeries),
        targetSeries: List<int>.from(_targetSeries),
      ),
    );

    pause();
    _startTime = null;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _repository.clear();
    notifyListeners();
  }

  void _tick() {
    int tickTarget = _targetSpm;

    if (_mode == TrainingMode.interval) {
      final bool hard = (_spmSeries.length ~/ 60).isEven;
      tickTarget += hard ? 6 : -6;
    }

    if (_slopeAdaptiveEnabled) {
      if (_slopePercent >= 4) {
        tickTarget -= 6;
      } else if (_slopePercent <= -4) {
        tickTarget += 4;
      }
    }

    if (_currentSpm == 0) {
      final int drift = _random.nextInt(9) - 4;
      _currentSpm = (_targetSpm + drift).clamp(minSpm, maxSpm);
    }

    if (_adaptiveEnabled) {
      final int delta = tickTarget - _currentSpm;
      if (delta.abs() >= 5) {
        _currentSpm += delta.sign * 2;
      }
    }

    _targetSeries.add(tickTarget);
    _spmSeries.add(_currentSpm);
    if (_spmSeries.length > 3600) {
      _spmSeries.removeAt(0);
      _targetSeries.removeAt(0);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _feedbackEngine.dispose();
    _detector.dispose();
    super.dispose();
  }
}
