import 'package:flutter/material.dart';
import 'dart:ui';

class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final double strokeWidth;
  final Color color;
  final double gap;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const DashedBorderContainer({
    super.key,
    required this.child,
    this.strokeWidth = 2.0,
    this.color = Colors.white,
    this.gap = 5.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(12.0)),
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          strokeWidth: strokeWidth,
          color: color,
          gap: gap,
          borderRadius: borderRadius,
        ),
        child: Container(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double gap;
  final BorderRadius borderRadius;

  _DashedBorderPainter({
    required this.strokeWidth,
    required this.color,
    required this.gap,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, size.height),
        topLeft: borderRadius.topLeft,
        topRight: borderRadius.topRight,
        bottomLeft: borderRadius.bottomLeft,
        bottomRight: borderRadius.bottomRight,
      ));

    final Path dashedPath = _dashPath(path, width: 10, space: gap);
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(Path source, {required double width, required double space}) {
    final Path path = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        path.addPath(
          metric.extractPath(distance, distance + width),
          Offset.zero,
        );
        distance += width + space;
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color ||
        oldDelegate.gap != gap ||
        oldDelegate.borderRadius != borderRadius;
  }
}
