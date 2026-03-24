import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/file_picker_util.dart';
import '../../auth/services/auth_provider.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _idCtrl;

  String? _frontUrl;
  String? _backUrl;
  String? _selfieUrl;
  bool _submitting = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _idCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(String label) async {
    final picked = await FilePickerUtil.pickImage();
    if (picked == null) return null;

    setState(() => _uploading = true);
    try {
      final api = ApiClient();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(picked.bytes,
            filename: picked.name,
            contentType: MediaType('image', 'jpeg')),
      });
      final res = await api.dio.post('/upload/image', data: formData);
      return res.data['url'] as String?;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải ảnh lên')));
      }
      return null;
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_frontUrl == null || _backUrl == null || _selfieUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tải đủ 3 ảnh xác minh')));
      return;
    }
    setState(() => _submitting = true);
    // Giả lập gửi yêu cầu (thực tế có thể gọi API riêng)
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yêu cầu xác minh đã được gửi! Chúng tôi sẽ xem xét trong 1-3 ngày làm việc.'),
        backgroundColor: AppTheme.secondary,
        duration: Duration(seconds: 4),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_left,
                color: Color(0xFF1A1A1A), size: 22),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text('Xác minh danh tính',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trạng thái xác minh
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: user?.isVerified == true
                            ? AppTheme.secondary.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: user?.isVerified == true
                              ? AppTheme.secondary.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            user?.isVerified == true
                                ? Icons.verified_user
                                : Icons.info_outline,
                            color: user?.isVerified == true
                                ? AppTheme.secondary
                                : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              user?.isVerified == true
                                  ? 'Tài khoản của bạn đã được xác minh'
                                  : 'Tài khoản chưa được xác minh. Xác minh để tăng độ tin cậy.',
                              style: TextStyle(
                                fontSize: 13,
                                color: user?.isVerified == true
                                    ? AppTheme.secondary
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Họ tên
                    const Text('Họ và tên (theo CCCD)',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: _inputDeco('Nhập họ và tên'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Nhập họ và tên' : null,
                    ),
                    const SizedBox(height: 20),

                    // Số CCCD
                    const Text('Số CCCD / CMND',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _idCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                      decoration: _inputDeco('Nhập số CCCD / CMND'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Nhập số CCCD';
                        if (v.length < 9) return 'Số CCCD không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Upload ảnh
                    const Text('Ảnh xác minh',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                      'Tải lên ảnh CCCD mặt trước, mặt sau và ảnh selfie cầm CCCD',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _ImageUploadBox(
                            label: 'Mặt trước',
                            icon: Icons.credit_card,
                            imageUrl: _frontUrl,
                            onTap: _uploading
                                ? null
                                : () async {
                                    final url = await _uploadImage('front');
                                    if (url != null) setState(() => _frontUrl = url);
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ImageUploadBox(
                            label: 'Mặt sau',
                            icon: Icons.credit_card_outlined,
                            imageUrl: _backUrl,
                            onTap: _uploading
                                ? null
                                : () async {
                                    final url = await _uploadImage('back');
                                    if (url != null) setState(() => _backUrl = url);
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ImageUploadBox(
                            label: 'Selfie',
                            icon: Icons.face,
                            imageUrl: _selfieUrl,
                            onTap: _uploading
                                ? null
                                : () async {
                                    final url = await _uploadImage('selfie');
                                    if (url != null) setState(() => _selfieUrl = url);
                                  },
                          ),
                        ),
                      ],
                    ),

                    if (_uploading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(color: AppTheme.secondary),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Nút xác minh
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: GestureDetector(
                onTap: (_submitting || _uploading) ? null : _submit,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF81D4FA)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Center(
                    child: _submitting
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Gửi yêu cầu xác minh',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.secondary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

class _ImageUploadBox extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? imageUrl;
  final VoidCallback? onTap;
  const _ImageUploadBox({
    required this.label,
    required this.icon,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: imageUrl != null
                ? AppTheme.secondary.withValues(alpha: 0.5)
                : const Color(0xFFDDDDDD),
          ),
          image: imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(imageUrl!), fit: BoxFit.cover)
              : null,
        ),
        child: imageUrl == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 28, color: AppTheme.textSecondary),
                  const SizedBox(height: 6),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: AppTheme.secondary, shape: BoxShape.circle),
                      child: const Icon(Icons.check,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
