import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String mode; // 'register' | 'forgot'
  final Map<String, dynamic>? registerData; // fullName, password khi mode=register
  const OtpScreen({super.key, required this.email, this.mode = 'forgot', this.registerData});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _resending = false;

  bool get _filled => _ctrls.every((c) => c.text.isNotEmpty);
  String get _code => _ctrls.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  void _onChanged(int i, String val) {
    if (val.length == 1 && i < 5) _nodes[i + 1].requestFocus();
    else if (val.isEmpty && i > 0) _nodes[i - 1].requestFocus();
    setState(() {});
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await AuthService().sendOtp(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lại mã!'), backgroundColor: AppTheme.secondary),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi lại mã'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    if (!_filled || _loading) return;
    setState(() => _loading = true);
    try {
      // Verify OTP với backend
      await AuthService().verifyOtp(widget.email, _code);
      if (!mounted) return;

      if (widget.mode == 'register') {
        // OTP đúng → đăng ký tài khoản (không tự login, để user tự đăng nhập)
        final data = widget.registerData!;
        await AuthService().register(
          fullName: data['fullName'] as String,
          email: data['email'] as String,
          password: data['password'] as String,
          phoneNumber: null,
        );
        if (!mounted) return;
        context.go('/register-success');
      } else {
        context.go('/reset-password', extra: {'email': widget.email});
      }
    } catch (e) {
      if (!mounted) return;
      // Parse lỗi từ backend
      String msg = 'Mã xác thực không đúng hoặc đã hết hạn';
      try {
        final data = (e as dynamic).response?.data;
        if (data?['message'] != null) msg = data['message'];
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
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
              _WaveHeader(mode: widget.mode),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.mode == 'register' ? 'Đăng Ký' : 'Quên Mật Khẩu',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Vui lòng nhập mã xác thực được gửi đến',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Color(0xFF777777)),
                      ),
                      const SizedBox(height: 28),
                      // 6 ô OTP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (i) => _OtpBox(
                          controller: _ctrls[i],
                          focusNode: _nodes[i],
                          onChanged: (v) => _onChanged(i, v),
                        )),
                      ),
                      const SizedBox(height: 24),
                      // Gửi lại
                      Column(
                        children: [
                          const Text(
                            'Tôi chưa nhận được mã',
                            style: TextStyle(fontSize: 13, color: Color(0xFF777777)),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: _resending ? null : _resend,
                            child: _resending
                                ? const SizedBox(width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondary))
                                : const Text(
                                    'Gửi lại',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Nút Xác Thực
                      GestureDetector(
                        onTap: _loading ? null : _verify,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: _filled
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
                              : Text(
                                  widget.mode == 'register' ? 'Xác Nhận' : 'Xác Thực',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                        ),
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

// ---- Ô nhập OTP ----
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  const _OtpBox({required this.controller, required this.focusNode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        shape: BoxShape.circle,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// ---- Header: phone icon + sóng ----
class _WaveHeader extends StatelessWidget {
  final String mode;
  const _WaveHeader({required this.mode});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleBtn(icon: Icons.chevron_left, onTap: () => context.go(
                      mode == 'register' ? '/register' : '/forgot-password'
                    )),
                    _CircleBtn(icon: Icons.home_outlined, onTap: () => context.go('/')),
                  ],
                ),
              ),
              const Spacer(),
              // Phone illustration
              Container(
                width: 110, height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 2.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Notch
                    Container(
                      width: 40, height: 8,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF42A5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.email_rounded, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
