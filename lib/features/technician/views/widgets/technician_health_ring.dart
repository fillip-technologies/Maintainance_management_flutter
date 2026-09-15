import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

/// Replicates the HealthRing from the web UI (http://localhost:5173/clientadmin/products).
/// Circular SVG-style ring with percentage in the center and color-coded status:
/// - Green (100%): All units nominal.
/// - Amber (>= 75%): Minor issues.
/// - Red (< 75%): Critical outages or multiple defects.
class TechnicianHealthRing extends StatelessWidget {
  final double percentage;
  final double size;
  final double strokeWidth;

  const TechnicianHealthRing({
    super.key,
    required this.percentage,
    this.size = 44.0,
    this.strokeWidth = 3.5,
  });

  @override
  Widget build(BuildContext context) {
    final pct = percentage.clamp(0.0, 100.0).round();
    final Color ringColor;
    if (pct == 100) {
      ringColor = AppColors.success;
    } else if (pct >= 75) {
      ringColor = AppColors.warning;
    } else {
      ringColor = AppColors.error;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: pct / 100.0,
              color: ringColor,
              trackColor: AppColors.textSecondary.withValues(alpha: 0.15),
              strokeWidth: strokeWidth,
            ),
          ),
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: ringColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Active arc
    if (progress > 0) {
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
