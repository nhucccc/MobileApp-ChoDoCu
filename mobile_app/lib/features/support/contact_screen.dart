import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_left,
                color: Color(0xFF1A1A1A), size: 22),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Liên hệ',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A)),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mô tả
            const Text(
              'Nếu cần hỗ trợ hoặc có thắc mắc trong quá trình sử dụng ứng dụng, người dùng có thể liên hệ với chúng tôi thông qua các kênh hỗ trợ được cung cấp. Đội ngũ hỗ trợ sẽ tiếp nhận và phản hồi trong thời gian sớm nhất nhằm đảm bảo quyền lợi và trải nghiệm của người dùng.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF444444),
                height: 1.7,
              ),
            ),
            const SizedBox(height: 28),

            // Email row
            _ContactRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: 'hotro@gmail.com',
            ),
            const SizedBox(height: 16),

            // Hotline row
            _ContactRow(
              icon: Icons.phone_outlined,
              label: 'Hotline',
              value: '0123456789',
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContactRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 15, color: Color(0xFF1A1A1A))),
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 15, color: Color(0xFF1A1A1A))),
      ],
    );
  }
}
