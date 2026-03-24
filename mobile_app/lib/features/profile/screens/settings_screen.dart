import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/services/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _lang = 'VI';
  bool _deleting = false;

  void _pickLanguage() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
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
              const Text('Chọn ngôn ngữ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...{
                'VI': '🇻🇳  Tiếng Việt',
                'EN': '🇺🇸  English',
              }.entries.map((e) => ListTile(
                    title: Text(e.value),
                    trailing: _lang == e.key
                        ? const Icon(Icons.check, color: AppTheme.secondary)
                        : null,
                    onTap: () {
                      setState(() => _lang = e.key);
                      setModalState(() {});
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.key == 'VI'
                              ? 'Đã chuyển sang Tiếng Việt'
                              : 'Switched to English'),
                          backgroundColor: AppTheme.secondary,
                        ),
                      );
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteAccount() {
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hành động này không thể hoàn tác. Tất cả dữ liệu của bạn sẽ bị xóa vĩnh viễn.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text('Nhập "XÓA" để xác nhận:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              decoration: InputDecoration(
                hintText: 'XÓA',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              if (confirmCtrl.text.trim() != 'XÓA') {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nhập "XÓA" để xác nhận')));
                return;
              }
              Navigator.pop(context);
              setState(() => _deleting = true);
              try {
                await context.read<AuthProvider>().deleteAccount();
                if (context.mounted) context.go('/login');
              } catch (_) {
                if (mounted) {
                  setState(() => _deleting = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Không thể xóa tài khoản')));
                }
              }
            },
            child: const Text('Xóa tài khoản',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Cài đặt',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: _deleting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.error),
                  SizedBox(height: 16),
                  Text('Đang xóa tài khoản...',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Ngôn ngữ
                      InkWell(
                        onTap: _pickLanguage,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.language,
                                  size: 20, color: Color(0xFF1A1A1A)),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('Ngôn ngữ',
                                    style: TextStyle(
                                        fontSize: 15, color: Color(0xFF1A1A1A))),
                              ),
                              Text(
                                _lang == 'VI' ? '🇻🇳 Tiếng Việt' : '🇺🇸 English',
                                style: const TextStyle(
                                    fontSize: 14, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right,
                                  size: 18, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),

                      // Đổi mật khẩu
                      InkWell(
                        onTap: () => context.push('/forgot-password'),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              Icon(Icons.lock_outline,
                                  size: 20, color: Color(0xFF1A1A1A)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text('Đổi mật khẩu',
                                    style: TextStyle(
                                        fontSize: 15, color: Color(0xFF1A1A1A))),
                              ),
                              Icon(Icons.chevron_right,
                                  size: 18, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Xóa tài khoản — tách riêng để nổi bật
                Container(
                  color: Colors.white,
                  child: InkWell(
                    onTap: _deleteAccount,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever_outlined,
                              size: 20, color: AppTheme.error),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Xóa tài khoản',
                                style: TextStyle(
                                    fontSize: 15, color: AppTheme.error)),
                          ),
                          Icon(Icons.chevron_right,
                              size: 18, color: AppTheme.error),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
