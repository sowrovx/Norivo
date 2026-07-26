/// Vector route illustration widget displayed inside the "Today's Journey" empty state.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class RouteIllustration extends StatelessWidget {
  const RouteIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: SizedBox(
          width: 80,
          height: 60,
          child: CustomPaint(
            painter: _RoutePathPainter(),
          ),
        ),
      ),
    );
  }
}

class _RoutePathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final startPoint = Offset(size.width * 0.15, size.height * 0.85);
    final endPoint = Offset(size.width * 0.85, size.height * 0.15);

    // Draw dashed path line
    final linePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final distance = (endPoint - startPoint).distance;
    const dashLength = 6.0;
    const dashSpace = 4.0;

    final dx = (endPoint.dx - startPoint.dx) / distance;
    final dy = (endPoint.dy - startPoint.dy) / distance;

    double currentDist = 0.0;
    while (currentDist < distance) {
      final p1 = Offset(
        startPoint.dx + dx * currentDist,
        startPoint.dy + dy * currentDist,
      );
      final p2Dist = (currentDist + dashLength).clamp(0.0, distance);
      final p2 = Offset(
        startPoint.dx + dx * p2Dist,
        startPoint.dy + dy * p2Dist,
      );
      canvas.drawLine(p1, p2, linePaint);
      currentDist += dashLength + dashSpace;
    }

    // Draw origin node (hollow / lighter blue circle)
    final originPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(startPoint, 6, originPaint);

    // Draw destination node (solid vibrant primary blue circle)
    final destPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPoint, 7, destPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
