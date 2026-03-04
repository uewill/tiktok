import 'package:shared_preferences/shared_preferences.dart';

import '../models/run_session.dart';

class SessionRepository {
  static const String _key = 'stepflow.sessions.v1';
  final List<RunSession> _sessions = <RunSession>[];
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final List<String> raw = _prefs?.getStringList(_key) ?? <String>[];
    _sessions
      ..clear()
      ..addAll(raw.map(RunSession.fromJson));
  }

  List<RunSession> all() => List<RunSession>.unmodifiable(_sessions.reversed);

  Future<void> add(RunSession session) async {
    _sessions.add(session);
    await _persist();
  }

  Future<void> clear() async {
    _sessions.clear();
    await _persist();
  }

  double weeklyAvgSpm() {
    if (_sessions.isEmpty) return 0;
    final DateTime weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final List<RunSession> weekly =
        _sessions.where((RunSession s) => s.startTime.isAfter(weekAgo)).toList();
    if (weekly.isEmpty) return 0;
    return weekly.map((RunSession s) => s.avgSpm).reduce((double a, double b) => a + b) /
        weekly.length;
  }

  double monthlyAvgSpm() {
    if (_sessions.isEmpty) return 0;
    final DateTime monthAgo = DateTime.now().subtract(const Duration(days: 30));
    final List<RunSession> monthly =
        _sessions.where((RunSession s) => s.startTime.isAfter(monthAgo)).toList();
    if (monthly.isEmpty) return 0;
    return monthly
            .map((RunSession s) => s.avgSpm)
            .reduce((double a, double b) => a + b) /
        monthly.length;
  }

  Future<void> _persist() async {
    final List<String> encoded = _sessions.map((RunSession s) => s.toJson()).toList();
    await _prefs?.setStringList(_key, encoded);
  }
}
