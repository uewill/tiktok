import 'dart:math' as math;

import 'package:flutter/material.dart';

class SpmChart extends StatelessWidget {
  const SpmChart({
    super.key,
    required this.data,
    required this.target,
  });

  final List<int> data;
  final List<int> target;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: _ChartPainter(data: data, target: target),
        size: Size.infinite,
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.data, required this.target});

  final List<int> data;
  final List<int> target;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2 || target.length < 2) return;

    final int minVal = <int>[...data, ...target].reduce(math.min);
    final int maxVal = <int>[...data, ...target].reduce(math.max);
    final double range = (maxVal - minVal).clamp(1, 999).toDouble();

    Path buildPath(List<int> values) {
      final Path path = Path();
      for (int i = 0; i < values.length; i++) {
        final double x = size.width * i / (values.length - 1);
        final double normalized = (values[i] - minVal) / range;
        final double y = size.height * (1 - normalized);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      return path;
    }

    final Paint targetPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Paint linePaint = Paint()
      ..color = const Color(0xFF4CC9F0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(buildPath(target), targetPaint);
    canvas.drawPath(buildPath(data), linePaint);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.target != target;
}
