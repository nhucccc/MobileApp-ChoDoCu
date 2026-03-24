import 'package:flutter/material.dart';

/// Logo chính của app: túi cam + lá xanh
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C00).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _LogoPainter(),
        size: Size(size, size),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width;

    // Thân túi cam
    final bagPaint = Paint()..color = const Color(0xFFFF8C00)..style = PaintingStyle.fill;
    final bagW = s * 0.52;
    final bagH = s * 0.50;
    final bagLeft = cx - bagW / 2;
    final bagTop = cy - bagH * 0.35;
    final bagRight = cx + bagW / 2;
    final bagBottom = bagTop + bagH;
    canvas.drawRRect(
      RRect.fromLTRBR(bagLeft, bagTop, bagRight, bagBottom, Radius.circular(s * 0.09)),
      bagPaint,
    );

    // 2 quai tròn
    final handleR = s * 0.075;
    final holePaint = Paint()..color = const Color(0xFF66BB6A)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - s * 0.13, bagTop - handleR * 0.3), handleR, bagPaint);
    canvas.drawCircle(Offset(cx + s * 0.13, bagTop - handleR * 0.3), handleR, bagPaint);
    canvas.drawCircle(Offset(cx - s * 0.13, bagTop - handleR * 0.3), handleR * 0.52, holePaint);
    canvas.drawCircle(Offset(cx + s * 0.13, bagTop - handleR * 0.3), handleR * 0.52, holePaint);

    // Vòng tròn xanh lá giữa túi
    final circlePaint = Paint()..color = const Color(0xFF4CAF50)..style = PaintingStyle.fill;
    final circleCenter = Offset(cx, bagTop + bagH * 0.52);
    canvas.drawCircle(circleCenter, s * 0.155, circlePaint);

    // Mũi tên recycle
    final arrowPaint = Paint()
      ..color = const Color(0xFFFF8C00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.022
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: circleCenter, radius: s * 0.155 * 0.62),
      -2.2, 4.4, false, arrowPaint,
    );
    final ah = Path();
    final cr = s * 0.155;
    ah.moveTo(circleCenter.dx + cr * 0.58, circleCenter.dy - cr * 0.18);
    ah.lineTo(circleCenter.dx + cr * 0.72, circleCenter.dy + cr * 0.05);
    ah.lineTo(circleCenter.dx + cr * 0.42, circleCenter.dy + cr * 0.05);
    ah.close();
    canvas.drawPath(ah, Paint()..color = const Color(0xFFFF8C00)..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
