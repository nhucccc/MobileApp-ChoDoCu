import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_provider.dart';
import '../services/auth_service.dart';
import '../../../core/widgets/app_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _agreed = false;
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onChanged);
    _emailCtrl.addListener(_onChanged);
    _passCtrl.addListener(_onChanged);
  }

  void _onChanged() {
    final has = _nameCtrl.text.isNotEmpty &&
        _emailCtrl.text.isNotEmpty &&
        _passCtrl.text.isNotEmpty;
    if (has != _hasInput) setState(() => _hasInput = has);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_hasInput) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý điều khoản dịch vụ'), backgroundColor: AppTheme.error),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    // Hiện loading
    setState(() {});
    try {
      // Gửi OTP trước
      await AuthService().sendOtp(_emailCtrl.text.trim());
      if (!mounted) return;
      // Chuyển sang OTP screen, kèm data đăng ký
      context.push('/otp', extra: {
        'email': _emailCtrl.text.trim(),
        'mode': 'register',
        'fullName': _nameCtrl.text.trim(),
        'password': _passCtrl.text,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().contains('message')
              ? 'Không thể gửi email xác thực'
              : 'Lỗi: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canSubmit = _hasInput && _agreed;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _WaveHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text('Đăng Ký',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                      ),
                      const SizedBox(height: 20),
                      // Tên tài khoản
                      const Text('Tên tài khoản :', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                      const SizedBox(height: 6),
                      _RoundedField(controller: _nameCtrl, hint: ''),
                      const SizedBox(height: 14),
                      // Email
                      const Text('Email / Số điện thoại :', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                      const SizedBox(height: 6),
                      _RoundedField(controller: _emailCtrl, hint: '', keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 14),
                      // Mật khẩu
                      const Text('Mật khẩu :', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                      const SizedBox(height: 6),
                      _RoundedField(
                        controller: _passCtrl,
                        hint: '',
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: const Color(0xFF999999), size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Checkbox điều khoản
                      Row(
                        children: [
                          SizedBox(
                            width: 20, height: 20,
                            child: Checkbox(
                              value: _agreed,
                              onChanged: (v) => setState(() => _agreed = v ?? false),
                              activeColor: AppTheme.secondary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              side: const BorderSide(color: Color(0xFFAAAAAA)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Đồng ý bởi ', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              'Các điều khoản và dịch vụ',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEA4335))),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const _SocialIcon(child: Icon(Icons.facebook, color: Color(0xFF1877F2), size: 26)),
                          const SizedBox(width: 16),
                          const _SocialIcon(child: Icon(Icons.apple, color: Colors.black, size: 26)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Bottom wave + nút Đăng Ký
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _BottomSection(
              loading: auth.loading,
              canSubmit: canSubmit,
              onTap: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Header ----
class _WaveHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TopWaveClipper(),
      child: Container(
        height: 220,
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
                    _CircleBtn(icon: Icons.chevron_left, onTap: () => context.go('/onboarding')),
                    _CircleBtn(icon: Icons.home_outlined, onTap: () => context.go('/')),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              AppLogo(size: 68),
              const SizedBox(height: 8),
              const Text('Oldie Market',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Bottom wave + nút ----
class _BottomSection extends StatelessWidget {
  final bool loading;
  final bool canSubmit;
  final VoidCallback onTap;
  const _BottomSection({required this.loading, required this.canSubmit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        ClipPath(
          clipper: _BottomWaveClipper(),
          child: Container(
            height: 90,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)]),
            ),
          ),
        ),
        Positioned(
          bottom: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Đã có tài khoản ? ', style: TextStyle(color: Colors.white, fontSize: 13)),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: const Text('Đăng nhập',
                    style: TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline, decorationColor: Colors.white,
                    )),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 55, right: 28,
          child: GestureDetector(
            onTap: loading ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              decoration: BoxDecoration(
                gradient: canSubmit
                    ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF1565C0)])
                    : null,
                color: canSubmit ? null : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              alignment: Alignment.center,
              child: loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Đăng Ký',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: canSubmit ? Colors.white : const Color(0xFF555555),
                      )),
            ),
          ),
        ),
      ],
    );
  }
}

// ---- Shared widgets ----
class _RoundedField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  const _RoundedField({
    required this.controller, required this.hint,
    this.obscure = false, this.suffix, this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: AppTheme.secondary, width: 1.5)),
      ),
    );
  }
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
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Center(child: child),
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
