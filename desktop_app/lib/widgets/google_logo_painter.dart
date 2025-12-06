import 'package:flutter/material.dart';

class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // The SVG paths are based on a 24x24 viewport.
    // We scale the canvas to fit the requested size (e.g., 20x20 or whatever is passed).
    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;

    canvas.scale(scaleX, scaleY);

    final paint = Paint()..style = PaintingStyle.fill;

    // Blue Path
    // d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
    final bluePath = Path();
    bluePath.moveTo(22.56, 12.25);
    bluePath.cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0);
    bluePath.lineTo(12.0, 10.0);
    bluePath.lineTo(12.0, 14.26);
    bluePath.lineTo(17.92, 14.26);
    bluePath.cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57);
    bluePath.lineTo(15.71, 20.34);
    bluePath.lineTo(19.28, 20.34);
    bluePath.cubicTo(21.36, 18.42, 22.56, 15.6, 22.56, 12.25);
    bluePath.close();
    
    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(bluePath, paint);

    // Green Path
    // d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
    final greenPath = Path();
    greenPath.moveTo(12.0, 23.0);
    greenPath.cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.34);
    greenPath.lineTo(15.71, 17.57);
    greenPath.cubicTo(14.73, 18.23, 13.48, 18.63, 12.0, 18.63);
    greenPath.cubicTo(9.14, 18.63, 6.71, 16.7, 5.84, 14.1);
    greenPath.lineTo(2.18, 14.1);
    greenPath.lineTo(2.18, 16.94);
    greenPath.cubicTo(3.99, 20.53, 7.7, 23.0, 12.0, 23.0);
    greenPath.close();

    paint.color = const Color(0xFF34A853);
    canvas.drawPath(greenPath, paint);

    // Yellow Path
    // d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"
    final yellowPath = Path();
    yellowPath.moveTo(5.84, 14.09);
    yellowPath.cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.0);
    yellowPath.cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91);
    yellowPath.lineTo(5.84, 7.07);
    yellowPath.lineTo(2.18, 7.07);
    yellowPath.cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0);
    yellowPath.cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.93);
    yellowPath.lineTo(5.84, 14.09);
    yellowPath.close();

    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(yellowPath, paint);

    // Red Path
    // d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
    final redPath = Path();
    redPath.moveTo(12.0, 5.38);
    redPath.cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02);
    redPath.lineTo(19.36, 3.87);
    redPath.cubicTo(17.45, 2.09, 14.97, 1.0, 12.0, 1.0);
    redPath.cubicTo(7.7, 1.0, 3.99, 3.47, 2.18, 7.07);
    redPath.lineTo(5.84, 9.91);
    redPath.cubicTo(6.71, 7.31, 9.14, 5.38, 12.0, 5.38);
    redPath.close();

    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(redPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
