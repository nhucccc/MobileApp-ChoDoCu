import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/services/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      context.go(auth.isLoggedIn ? '/' : '/onboarding');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF66BB6A), Color(0xFFA5D6A7)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Logo giữa màn hình
              Center(
                child: ScaleTransition(
                  scale: _scale,
                  child: const _OldieMarketLogo(size: 120),
                ),
              ),
              // Text dưới cùng
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fade,
                  child: const Text(
                    'Oldie Market',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OldieMarketLogo extends StatelessWidget {
  final double size;
  const _OldieMarketLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.4,
      height: size * 1.4,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width;

    // --- 2 lá xanh đậm hai bên ---
    final leafPaint = Paint()..color = const Color(0xFF388E3C)..style = PaintingStyle.fill;

    // Lá trái
    final leftLeaf = Path();
    leftLeaf.moveTo(cx - s * 0.30, cy + s * 0.05);
    leftLeaf.cubicTo(cx - s * 0.42, cy - s * 0.10, cx - s * 0.48, cy + s * 0.12, cx - s * 0.38, cy + s * 0.20);
    leftLeaf.cubicTo(cx - s * 0.28, cy + s * 0.28, cx - s * 0.22, cy + s * 0.14, cx - s * 0.30, cy + s * 0.05);
    canvas.drawPath(leftLeaf, leafPaint);

    // Lá phải
    final rightLeaf = Path();
    rightLeaf.moveTo(cx + s * 0.30, cy + s * 0.05);
    rightLeaf.cubicTo(cx + s * 0.42, cy - s * 0.10, cx + s * 0.48, cy + s * 0.12, cx + s * 0.38, cy + s * 0.20);
    rightLeaf.cubicTo(cx + s * 0.28, cy + s * 0.28, cx + s * 0.22, cy + s * 0.14, cx + s * 0.30, cy + s * 0.05);
    canvas.drawPath(rightLeaf, leafPaint);

    // --- Thân túi cam (hình vuông bo góc) ---
    final bagPaint = Paint()..color = const Color(0xFFFF8C00)..style = PaintingStyle.fill;
    final bagW = s * 0.52;
    final bagH = s * 0.50;
    final bagLeft = cx - bagW / 2;
    final bagTop = cy - bagH * 0.35;
    final bagRight = cx + bagW / 2;
    final bagBottom = bagTop + bagH;
    final bagRRect = RRect.fromLTRBR(bagLeft, bagTop, bagRight, bagBottom, Radius.circular(s * 0.09));
    canvas.drawRRect(bagRRect, bagPaint);

    // --- 2 quai tròn trên ---
    final handlePaint = Paint()
      ..color = const Color(0xFFFF8C00)
      ..style = PaintingStyle.fill;
    final handleR = s * 0.075;
    // quai trái
    canvas.drawCircle(Offset(cx - s * 0.13, bagTop - handleR * 0.3), handleR, handlePaint);
    // quai phải
    canvas.drawCircle(Offset(cx + s * 0.13, bagTop - handleR * 0.3), handleR, handlePaint);
    // lỗ quai (khoét trắng)
    final holePaint = Paint()..color = const Color(0xFF66BB6A)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - s * 0.13, bagTop - handleR * 0.3), handleR * 0.52, holePaint);
    canvas.drawCircle(Offset(cx + s * 0.13, bagTop - handleR * 0.3), handleR * 0.52, holePaint);

    // --- Vòng tròn xanh lá ở giữa túi ---
    final circleBgPaint = Paint()..color = const Color(0xFF4CAF50)..style = PaintingStyle.fill;
    final circleR = s * 0.155;
    final circleCenter = Offset(cx, bagTop + bagH * 0.52);
    canvas.drawCircle(circleCenter, circleR, circleBgPaint);

    // Mũi tên recycle (2 mũi tên cong tạo thành vòng tròn)
    final arrowPaint = Paint()
      ..color = const Color(0xFFFF8C00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.022
      ..strokeCap = StrokeCap.round;

    // Vẽ 2 cung tròn tạo hiệu ứng recycle
    canvas.drawArc(
      Rect.fromCircle(center: circleCenter, radius: circleR * 0.62),
      -2.2, 4.4, false, arrowPaint,
    );

    // Mũi tên nhỏ
    final arrowHeadPaint = Paint()
      ..color = const Color(0xFFFF8C00)
      ..style = PaintingStyle.fill;
    final ah = Path();
    ah.moveTo(circleCenter.dx + circleR * 0.58, circleCenter.dy - circleR * 0.18);
    ah.lineTo(circleCenter.dx + circleR * 0.72, circleCenter.dy + circleR * 0.05);
    ah.lineTo(circleCenter.dx + circleR * 0.42, circleCenter.dy + circleR * 0.05);
    ah.close();
    canvas.drawPath(ah, arrowHeadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
