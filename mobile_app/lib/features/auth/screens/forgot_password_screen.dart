import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _ctrl = TextEditingController();
  bool _hasInput = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.isNotEmpty;
      if (has != _hasInput) setState(() => _hasInput = has);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_ctrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await AuthService().sendOtp(_ctrl.text.trim());
      if (!mounted) return;
      context.push('/otp', extra: {
        'email': _ctrl.text.trim(),
        'mode': 'forgot',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi mã xác thực'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _WaveHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Quên Mật Khẩu',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Nhập Email / Số điện thoại :',
                        style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ctrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: AppTheme.secondary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Nút Gửi Mã
                      GestureDetector(
                        onTap: _loading ? null : _submit,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: _hasInput
                                ? const LinearGradient(
                                    colors: [Color(0xFF4CAF50), Color(0xFF42A5F5)],
                                  )
                                : const LinearGradient(
                                    colors: [Color(0xFFBDBDBD), Color(0xFFBDBDBD)],
                                  ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          alignment: Alignment.center,
                          child: _loading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text(
                                  'Gửi Mã',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Divider
                      Row(
                        children: const [
                          Expanded(child: Divider(color: Color(0xFFCCCCCC))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('Hoặc đăng nhập bằng',
                                style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                          ),
                          Expanded(child: Divider(color: Color(0xFFCCCCCC))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Social icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialIcon(
                            child: Image.network(
                              'https://www.google.com/favicon.ico',
                              width: 24, height: 24,
                              errorBuilder: (_, __, ___) => const Text('G',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                                      color: Color(0xFFEA4335))),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const _SocialIcon(
                            child: Icon(Icons.facebook, color: Color(0xFF1877F2), size: 26),
                          ),
                          const SizedBox(width: 16),
                          const _SocialIcon(
                            child: Icon(Icons.apple, color: Colors.black, size: 26),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Sóng dưới
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _BottomWave(),
          ),
        ],
      ),
    );
  }
}

// ---- Header xanh lá sóng cong ----
class _WaveHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TopWaveClipper(),
      child: Container(
        height: 230,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleBtn(icon: Icons.chevron_left, onTap: () => context.go('/login')),
                    _CircleBtn(icon: Icons.home_outlined, onTap: () => context.go('/')),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              AppLogo(size: 72),
              const SizedBox(height: 8),
              const Text(
                'Oldie Market',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
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

class _BottomWave extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _BottomWaveClipper(),
      child: Container(
        height: 70,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)]),
        ),
      ),
    );
  }
}

class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 35);
    path.quadraticBezierTo(size.width * 0.25, 5, size.width * 0.5, 28);
    path.quadraticBezierTo(size.width * 0.75, 52, size.width, 22);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

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

class _SocialIcon extends StatelessWidget {
  final Widget child;
  const _SocialIcon({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
