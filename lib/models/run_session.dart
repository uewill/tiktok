import 'dart:convert';

enum TrainingMode { easy, tempo, interval, race }

class RunSession {
  RunSession({
    required this.startTime,
    required this.endTime,
    required this.targetSpm,
    required this.avgSpm,
    required this.stability,
    required this.adherence,
    required this.mode,
    required this.spms,
    required this.targetSeries,
  });

  final DateTime startTime;
  final DateTime endTime;
  final int targetSpm;
  final double avgSpm;
  final double stability;
  final double adherence;
  final TrainingMode mode;
  final List<int> spms;
  final List<int> targetSeries;

  Duration get duration => endTime.difference(startTime);

  String get label {
    final int mins = duration.inMinutes;
    final int secs = duration.inSeconds % 60;
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'targetSpm': targetSpm,
      'avgSpm': avgSpm,
      'stability': stability,
      'adherence': adherence,
      'mode': mode.name,
      'spms': spms,
      'targetSeries': targetSeries,
    };
  }

  factory RunSession.fromMap(Map<String, dynamic> map) {
    return RunSession(
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      targetSpm: map['targetSpm'] as int,
      avgSpm: (map['avgSpm'] as num).toDouble(),
      stability: (map['stability'] as num).toDouble(),
      adherence: (map['adherence'] as num).toDouble(),
      mode: TrainingMode.values.firstWhere(
        (TrainingMode m) => m.name == map['mode'],
        orElse: () => TrainingMode.easy,
      ),
      spms: List<int>.from(map['spms'] as List<dynamic>),
      targetSeries: List<int>.from(map['targetSeries'] as List<dynamic>),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory RunSession.fromJson(String source) =>
      RunSession.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
