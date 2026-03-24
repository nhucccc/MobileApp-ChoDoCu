import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/utils/google_sign_in_platform.dart';
import '../../core/widgets/app_logo.dart';
import '../auth/services/auth_provider.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final idToken = await googleSignInWeb();
      if (!context.mounted) return;
      final auth = context.read<AuthProvider>();
      final ok = await auth.loginWithGoogle(idToken);
      if (!context.mounted) return;
      if (ok) {
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Đăng nhập thất bại'),
              backgroundColor: const Color(0xFFE53935)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đăng nhập bằng Google'),
            backgroundColor: Color(0xFFE53935)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ---- Header xanh lá + sóng ----
          _WaveHeader(),
          // ---- Nội dung phía dưới ----
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chào Mừng !',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Nút Đăng Ký
                  _GradientButton(
                    label: 'Đăng Ký',
                    onTap: () => context.go('/register'),
                  ),
                  const SizedBox(height: 14),
                  // Nút Đăng Nhập
                  _GradientButton(
                    label: 'Đăng Nhập',
                    onTap: () => context.go('/login'),
                  ),
                  const SizedBox(height: 28),
                  // Divider "Chọn cách đăng nhập khác"
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFFCCCCCC))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Chọn cách đăng nhập khác',
                          style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFCCCCCC))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Social icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialIcon(
                        onTap: () => _handleGoogleSignIn(context),
                        child: Image.network(
                          'https://www.google.com/favicon.ico',
                          width: 24, height: 24,
                          errorBuilder: (_, __, ___) => const Text('G',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEA4335))),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _SocialIcon(
                        onTap: () {},
                        child: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 26),
                      ),
                      const SizedBox(width: 16),
                      _SocialIcon(
                        onTap: () {},
                        child: const Icon(Icons.apple, color: Colors.black, size: 26),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Sóng dưới cùng
          _BottomWave(),
        ],
      ),
    );
  }
}

// ---- Header với sóng cong ----
class _WaveHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: _TopWaveClipper(),
          child: Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Back + Home buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CircleBtn(
                          icon: Icons.chevron_left,
                          onTap: () => context.go('/splash'),
                        ),
                        _CircleBtn(
                          icon: Icons.home_outlined,
                          onTap: () => context.go('/'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Logo
                  AppLogo(size: 80),
                  const SizedBox(height: 10),
                  const Text(
                    'Oldie Market',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height - 30);
    path.quadraticBezierTo(size.width * 0.75, size.height - 60, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ---- Sóng dưới cùng ----
class _BottomWave extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _BottomWaveClipper(),
      child: Container(
        height: 70,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
          ),
        ),
      ),
    );
  }
}

class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 30);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 25);
    path.quadraticBezierTo(size.width * 0.75, 50, size.width, 20);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ---- Nút gradient xanh lá → xanh dương ----
class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF42A5F5)],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---- Nút tròn (back/home) ----
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ---- Social icon box ----
class _SocialIcon extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _SocialIcon({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
