import 'package:flutter/material.dart';

import '../models/run_session.dart';
import '../services/metronome_controller.dart';
import '../widgets/spm_chart.dart';
import '../widgets/spm_ring.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MetronomeController? _controller;
  int _tab = 0;
  final TextEditingController _paceMinute = TextEditingController(text: '5');
  final TextEditingController _paceSecond = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final MetronomeController c = await MetronomeController.create();
    if (!mounted) return;
    setState(() => _controller = c);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _paceMinute.dispose();
    _paceSecond.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MetronomeController? controller = _controller;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(_tab == 0 ? 'StepFlow · 训练' : 'StepFlow · 记录')),
          body: _tab == 0 ? _buildTraining(controller) : _buildHistory(controller),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (int idx) => setState(() => _tab = idx),
            destinations: const <NavigationDestination>[
              NavigationDestination(icon: Icon(Icons.directions_run), label: '训练'),
              NavigationDestination(icon: Icon(Icons.insights), label: '记录'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTraining(MetronomeController c) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Center(child: SpmRing(current: c.currentSpm, target: c.targetSpm)),
        const SizedBox(height: 12),
        _modePicker(c),
        const SizedBox(height: 12),
        _paceRecommendation(c),
        const SizedBox(height: 12),
        _targetControl(c),
        const SizedBox(height: 8),
        _feedbackControl(c),
        const SizedBox(height: 8),
        _adaptiveControl(c),
        const SizedBox(height: 12),
        SpmChart(data: c.spmSeries, target: c.targetSeries),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                onPressed: c.running ? c.pause : c.start,
                icon: Icon(c.running ? Icons.pause : Icons.play_arrow),
                label: Text(c.running ? '暂停训练' : '快速开始'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: c.running || c.spmSeries.isNotEmpty ? c.stopAndSave : null,
                icon: const Icon(Icons.stop),
                label: const Text('结束并保存'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistory(MetronomeController c) {
    return HistoryScreen(
      sessions: c.history,
      weeklyAvg: c.weeklyAvg,
      monthlyAvg: c.monthlyAvg,
      onClear: c.clearHistory,
    );
  }

  Widget _modePicker(MetronomeController c) {
    return Wrap(
      spacing: 8,
      children: TrainingMode.values.map((TrainingMode mode) {
        return ChoiceChip(
          label: Text(_modeName(mode)),
          selected: mode == c.mode,
          onSelected: (_) => c.setMode(mode),
        );
      }).toList(),
    );
  }

  Widget _paceRecommendation(MetronomeController c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('按配速推荐步频', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _paceMinute,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '分'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _paceSecond,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '秒'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final int rec = c.recommendSpmByPace(
                    minPerKm: int.tryParse(_paceMinute.text) ?? 5,
                    secPerKm: int.tryParse(_paceSecond.text) ?? 30,
                  );
                  c.setTargetSpm(rec);
                },
                child: const Text('推荐'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _targetControl(MetronomeController c) {
    return Row(
      children: <Widget>[
        const Text('目标步频', style: TextStyle(fontSize: 16)),
        Expanded(
          child: Slider(
            value: c.targetSpm.toDouble(),
            min: MetronomeController.minSpm.toDouble(),
            max: MetronomeController.maxSpm.toDouble(),
            divisions: MetronomeController.maxSpm - MetronomeController.minSpm,
            label: '${c.targetSpm} SPM',
            onChanged: (double v) => c.setTargetSpm(v.round()),
          ),
        ),
      ],
    );
  }

  Widget _feedbackControl(MetronomeController c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            children: FeedbackType.values.map((FeedbackType type) {
              return FilterChip(
                label: Text(_feedbackName(type)),
                selected: c.feedback.contains(type),
                onSelected: (_) => c.toggleFeedback(type),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Text(
            '锁屏保活（防止熄屏中断）',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
          Switch(
            value: c.keepScreenOn,
            onChanged: c.toggleKeepScreenOn,
          ),
        ],
      ),
    );
  }

  Widget _adaptiveControl(MetronomeController c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('动态自适应（偏差 ≥ 5 SPM 自动微调）'),
            value: c.adaptiveEnabled,
            onChanged: c.toggleAdaptive,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('坡度自适应（上坡降节拍，下坡增节拍）'),
            value: c.slopeAdaptiveEnabled,
            onChanged: c.toggleSlopeAdaptive,
          ),
          Row(
            children: <Widget>[
              const Text('当前坡度模拟'),
              Expanded(
                child: Slider(
                  min: -15,
                  max: 15,
                  divisions: 30,
                  value: c.slopePercent,
                  label: '${c.slopePercent.toStringAsFixed(0)}%',
                  onChanged: c.setSlope,
                ),
              ),
              Text('${c.slopePercent.toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  String _modeName(TrainingMode mode) => switch (mode) {
        TrainingMode.easy => '日常',
        TrainingMode.tempo => '节奏跑',
        TrainingMode.interval => '间歇',
        TrainingMode.race => '比赛',
      };

  String _feedbackName(FeedbackType type) => switch (type) {
        FeedbackType.audio => '音频节拍',
        FeedbackType.vibration => '振动节拍',
        FeedbackType.voiceCount => '语音计数',
      };
}
