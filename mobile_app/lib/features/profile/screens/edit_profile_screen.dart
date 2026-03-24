import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/file_picker_util.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/net_image.dart';
import '../../auth/services/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _uploadingAvatar = false;
  bool _uploadingCover = false;
  bool _saving = false;

  late String _fullName;
  late String _phone;
  late String _email;
  String? _gender;
  DateTime? _birthday;
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _fullName = user?.fullName ?? '';
    _phone = user?.phoneNumber ?? '';
    _email = user?.email ?? '';
    _gender = user?.gender;
    _birthday = user?.birthday;
  }

  Future<String?> _uploadImage(bytes, String filename) async {
    try {
      final api = ApiClient();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes,
            filename: filename,
            contentType: MediaType('image', 'jpeg')),
      });
      final res = await api.dio.post('/upload/image', data: formData);
      return res.data['url'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await FilePickerUtil.pickImage();
    if (picked == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final url = await _uploadImage(picked.bytes, picked.name);
      if (url != null && mounted) {
        await context.read<AuthProvider>().updateProfile(avatarUrl: url);
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _pickCover() async {
    final picked = await FilePickerUtil.pickImage();
    if (picked == null) return;
    setState(() => _uploadingCover = true);
    try {
      final url = await _uploadImage(picked.bytes, picked.name);
      if (url != null && mounted) setState(() => _coverUrl = url);
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  void _editField(String title, String current,
      {TextInputType keyboard = TextInputType.text,
      required void Function(String) onSave}) {
    final ctrl = TextEditingController(text: current);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: keyboard,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onSave(ctrl.text.trim());
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Lưu',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickGender() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Giới tính',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...['Nam', 'Nữ', 'Khác'].map((g) => ListTile(
                  title: Text(g),
                  trailing: _gender == g
                      ? const Icon(Icons.check, color: AppTheme.secondary)
                      : null,
                  onTap: () {
                    setState(() => _gender = g);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile(
            fullName: _fullName,
            phone: _phone.isEmpty ? null : _phone,
            gender: _gender,
            birthday: _birthday,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cập nhật thành công'),
            backgroundColor: AppTheme.secondary),
      );
      context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật hồ sơ')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
        title: const Text('Hồ sơ',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: ListView(
        children: [
          // ---- Banner + Avatar ----
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner
              GestureDetector(
                onTap: _pickCover,
                child: Container(
                  height: 130,
                  decoration: BoxDecoration(
                    gradient: _coverUrl == null
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4DD0E1), Color(0xFF26C6DA)],
                          )
                        : null,
                    image: _coverUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_coverUrl!),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: Stack(children: [
                    if (_coverUrl == null) ...[
                      Positioned(right: 20, top: 15, child: _Cloud(size: 90)),
                      Positioned(right: 100, top: 8, child: _Cloud(size: 60)),
                      Positioned(left: 20, top: 20, child: _Cloud(size: 70)),
                    ],
                    if (_uploadingCover)
                      Container(
                        color: Colors.black38,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    Positioned(
                      top: 44, right: 12,
                      child: GestureDetector(
                        onTap: _pickCover,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt, size: 14, color: Color(0xFF1A1A1A)),
                              SizedBox(width: 4),
                              Text('Sửa ảnh bìa',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              // Avatar
              Positioned(
                bottom: -50,
                left: 0, right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8)
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: const Color(0xFFE0E0E0),
                            backgroundImage: user?.avatarUrl != null
                                ? netImageProvider(user!.avatarUrl!)
                                : null,
                            child: user?.avatarUrl == null
                                ? Text(
                                    (_fullName.isNotEmpty ? _fullName : 'U')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w700))
                                : null,
                          ),
                        ),
                        if (_uploadingAvatar)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.black26,
                                  shape: BoxShape.circle),
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: AppTheme.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 130),
            ],
          ),

          const SizedBox(height: 60),

          // ---- Fields ----
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _FieldRow(
                  label: 'Họ tên',
                  value: _fullName,
                  onTap: () => _editField('Họ tên', _fullName,
                      onSave: (v) => setState(() => _fullName = v)),
                ),
                const Divider(height: 1, indent: 16, color: Color(0xFFF0F0F0)),
                _FieldRow(
                  label: 'Giới tính',
                  value: _gender ?? '',
                  placeholder: 'Chưa cập nhật',
                  onTap: _pickGender,
                ),
                const Divider(height: 1, indent: 16, color: Color(0xFFF0F0F0)),
                _FieldRow(
                  label: 'Ngày sinh',
                  value: _birthday != null ? FormatUtils.formatDate(_birthday!) : '',
                  placeholder: 'Chưa cập nhật',
                  onTap: _pickBirthday,
                ),
                const Divider(height: 1, indent: 16, color: Color(0xFFF0F0F0)),
                _FieldRow(
                  label: 'Số điện thoại',
                  value: _phone,
                  placeholder: 'Chưa xác minh',
                  onTap: () => _editField(
                    'Số điện thoại', _phone,
                    keyboard: TextInputType.phone,
                    onSave: (v) => setState(() => _phone = v),
                  ),
                ),
                const Divider(height: 1, indent: 16, color: Color(0xFFF0F0F0)),
                _FieldRow(
                  label: 'Email',
                  value: _email,
                  onTap: null, // Email không thể thay đổi
                ),              ],
            ),
          ),

          const SizedBox(height: 24),

          // Nút lưu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _saving ? null : _saveAll,
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
                  child: _saving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Lưu thay đổi',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---- Field row ----
class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final String? placeholder;
  final VoidCallback? onTap;
  const _FieldRow({
    required this.label,
    required this.value,
    this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value.isEmpty;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A))),
            ),
            Expanded(
              child: Text(
                isEmpty ? (placeholder ?? '') : value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 15,
                    color: isEmpty
                        ? AppTheme.textSecondary
                        : const Color(0xFF1A1A1A)),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18,
                color: onTap != null ? AppTheme.textSecondary : Colors.transparent),
          ],
        ),
      ),
    );
  }
}

// ---- Cloud widget ----
class _Cloud extends StatelessWidget {
  final double size;
  const _Cloud({required this.size});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size * 0.6), painter: _CloudPainter());
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.3, h * 0.6), width: w * 0.5, height: h * 0.7))
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.55, h * 0.45), width: w * 0.55, height: h * 0.85))
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.75, h * 0.65), width: w * 0.4, height: h * 0.6))
      ..addRect(Rect.fromLTRB(w * 0.1, h * 0.6, w * 0.9, h));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
