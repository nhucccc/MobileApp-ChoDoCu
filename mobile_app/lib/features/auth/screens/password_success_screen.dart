import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class PasswordSuccessScreen extends StatelessWidget {
  final String mode; // 'password' | 'register'
  const PasswordSuccessScreen({super.key, this.mode = 'password'});

  @override
  Widget build(BuildContext context) {
    final isRegister = mode == 'register';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 28),
                        onPressed: () => context.pop(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.home_outlined, size: 26),
                        onPressed: () => context.go('/'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _SuccessIllustration(),
                const SizedBox(height: 36),
                Text(
                  isRegister ? 'Đăng ký thành công !' : 'Thay đổi mật khẩu thành công !',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    isRegister
                        ? 'Bạn đã đăng ký tài khoản thành công.\nVui lòng sử dụng tài khoản để Đăng nhập.'
                        : 'Bạn đã thay đổi mật khẩu thành công.\nVui lòng sử dụng mật khẩu mới để Đăng nhập.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF777777), height: 1.6),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF42A5F5)]),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: const Text('OK',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: ClipPath(
                clipper: _BottomWaveClipper(),
                child: Container(
                  height: 90,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Illustration vẽ bằng widget ----
class _SuccessIllustration extends StatelessWidget {
  const _SuccessIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Nền tròn nhạt
          Container(
            width: 260, height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          // Lá xanh trái
          Positioned(
            left: 10, top: 30,
            child: _Leaf(color: const Color(0xFF4CAF50), size: 48, flip: false),
          ),
          // Lá xanh phải
          Positioned(
            right: 10, top: 20,
            child: _Leaf(color: const Color(0xFF66BB6A), size: 40, flip: true),
          ),
          // Lá nhỏ phải dưới
          Positioned(
            right: 30, bottom: 20,
            child: _Leaf(color: const Color(0xFF4CAF50), size: 32, flip: true),
          ),
          // Điện thoại
          Positioned(
            left: 60,
            child: Container(
              width: 90, height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3949AB), width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36, height: 7,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3949AB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3949AB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 26),
                  ),
                ],
              ),
            ),
          ),
          // Khiên xanh
          Positioned(
            right: 55, top: 50,
            child: Container(
              width: 64, height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF3949AB),
              ),
              child: CustomPaint(painter: _ShieldPainter()),
            ),
          ),
          // Chìa khóa vàng
          Positioned(
            left: 50, bottom: 18,
            child: Transform.rotate(
              angle: -0.3,
              child: const Icon(Icons.vpn_key_rounded, color: Color(0xFFFFC107), size: 36),
            ),
          ),
          // Ổ khóa vàng
          Positioned(
            right: 40, bottom: 14,
            child: Container(
              width: 38, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _Leaf extends StatelessWidget {
  final Color color;
  final double size;
  final bool flip;
  const _Leaf({required this.color, required this.size, required this.flip});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flip ? -1 : 1,
      child: Icon(Icons.eco_rounded, color: color, size: size),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF3949AB)..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height * 0.25);
    path.lineTo(size.width, size.height * 0.6);
    path.quadraticBezierTo(size.width / 2, size.height, 0, size.height * 0.6);
    path.lineTo(0, size.height * 0.25);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 40);
    path.quadraticBezierTo(size.width * 0.25, 8, size.width * 0.5, 32);
    path.quadraticBezierTo(size.width * 0.75, 56, size.width, 24);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
