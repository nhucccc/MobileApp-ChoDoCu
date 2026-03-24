import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BuyerProtectionScreen extends StatelessWidget {
  const BuyerProtectionScreen({super.key});

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
          'Đảm bảo cho người mua',
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
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Text(
          'Ứng dụng cam kết tạo môi trường giao dịch minh bạch và an toàn cho người mua.\n'
          '    Mọi sản phẩm đăng bán phải cung cấp thông tin rõ ràng, đúng với tình trạng thực tế.\n'
          '    Người mua được khuyến khích trao đổi và giao dịch thông qua hệ thống của ứng dụng để đảm bảo quyền lợi.\n'
          '    Trong trường hợp phát sinh tranh chấp, người mua có thể gửi phản hồi để được hỗ trợ và xử lý theo quy định của nền tảng.',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF1A1A1A),
            height: 1.8,
          ),
        ),
      ),
    );
  }
}
