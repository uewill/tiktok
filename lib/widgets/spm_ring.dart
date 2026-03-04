import 'dart:math' as math;

import 'package:flutter/material.dart';

class SpmRing extends StatelessWidget {
  const SpmRing({
    super.key,
    required this.current,
    required this.target,
  });

  final int current;
  final int target;

  @override
  Widget build(BuildContext context) {
    final double ratio = (current / target).clamp(0.0, 1.3);
    final int diff = current - target;
    final String hint = diff.abs() <= 3
        ? '节奏稳定'
        : diff > 0
            ? '偏快 ${diff.abs()} SPM'
            : '偏慢 ${diff.abs()} SPM';

    return SizedBox(
      width: 250,
      height: 250,
      child: CustomPaint(
        painter: _RingPainter(progress: ratio),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('当前步频', style: TextStyle(color: Colors.white70)),
              Text(
                '$current SPM',
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
              ),
              Text('目标 $target', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(hint, style: const TextStyle(fontSize: 13, color: Colors.white60)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = math.min(size.width, size.height) / 2 - 10;

    final Paint bgPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    final Paint fgPaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFF00D1B2), Color(0xFF4CC9F0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
