import 'package:flutter/material.dart';

import '../models/run_session.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.sessions,
    required this.weeklyAvg,
    required this.monthlyAvg,
    required this.onClear,
  });

  final List<RunSession> sessions;
  final double weeklyAvg;
  final double monthlyAvg;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _StatCard(label: '周均步频', value: '${weeklyAvg.toStringAsFixed(1)}')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: '月均步频', value: '${monthlyAvg.toStringAsFixed(1)}')),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: sessions.isEmpty ? null : onClear,
            icon: const Icon(Icons.delete_outline),
            label: const Text('清空记录'),
          ),
        ),
        const SizedBox(height: 6),
        if (sessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('暂无训练记录，先去“训练”页面开始一次跑步吧。'),
          ),
        ...sessions.map((RunSession s) => _SessionTile(session: s)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final RunSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${session.startTime.month}/${session.startTime.day} · ${session.mode.name}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text('时长 ${session.label} | 目标 ${session.targetSpm} SPM'),
          Text(
            '平均 ${session.avgSpm.toStringAsFixed(1)} | 稳定性σ ${session.stability.toStringAsFixed(1)} | 达标 ${(session.adherence * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
