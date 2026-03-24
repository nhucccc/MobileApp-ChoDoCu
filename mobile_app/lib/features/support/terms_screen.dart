import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
          'Điều khoản và hướng dẫn',
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
      body: ListView(
        children: const [
          _SimpleItem(title: 'Điều khoản sử dụng (Chung)'),
          _Divider(),
          _ExpandableItem(
            title: 'Hướng dẫn sử dụng',
            children: [
              'Cách đăng ký / đăng nhập',
              'Cách mua hàng',
              'Cách đăng bán sản phẩm',
              'Cách nhắn tin trao đổi',
              'Quy trình giao dịch',
            ],
          ),
          _Divider(),
          _SimpleItem(title: 'Chính sách bảo mật'),
          _Divider(),
          _ExpandableItem(
            title: 'Câu hỏi thường gặp (FAQ)',
            children: [
              'Làm sao để đăng bán sản phẩm?',
              'Huỷ đơn hàng thế nào?',
              'Gặp tranh chấp thì xử lý ra sao?',
              'Liên hệ hỗ trợ ở đâu?',
            ],
          ),
          _Divider(),
          _SimpleItem(title: 'Hỗ trợ & liên hệ'),
          _Divider(),
        ],
      ),
    );
  }
}

// ---- Divider ----
class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: Color(0xFFEEEEEE), indent: 0);
}

// ---- Simple item (không expand) ----
class _SimpleItem extends StatelessWidget {
  final String title;
  const _SimpleItem({required this.title});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showContent(context, title),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A)),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showContent(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: ctrl,
                  child: Text(
                    _contentFor(title),
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF444444),
                        height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _contentFor(String title) {
    switch (title) {
      case 'Điều khoản sử dụng (Chung)':
        return 'Bằng cách sử dụng ứng dụng Chợ Đồ Cũ, bạn đồng ý tuân thủ các điều khoản và điều kiện sau đây.\n\n'
            '1. Người dùng phải từ 18 tuổi trở lên hoặc có sự đồng ý của phụ huynh.\n\n'
            '2. Nghiêm cấm đăng bán hàng giả, hàng nhái, hàng vi phạm pháp luật.\n\n'
            '3. Chúng tôi có quyền xóa bất kỳ tin đăng nào vi phạm quy định.\n\n'
            '4. Người dùng chịu trách nhiệm về tính chính xác của thông tin đăng tải.\n\n'
            '5. Chúng tôi không chịu trách nhiệm về các giao dịch giữa người dùng.';
      case 'Chính sách bảo mật':
        return 'Chúng tôi cam kết bảo vệ thông tin cá nhân của bạn.\n\n'
            '1. Thông tin thu thập: Tên, email, số điện thoại, địa chỉ giao hàng.\n\n'
            '2. Mục đích sử dụng: Xác thực tài khoản, xử lý giao dịch, hỗ trợ khách hàng.\n\n'
            '3. Chúng tôi không bán thông tin cá nhân cho bên thứ ba.\n\n'
            '4. Bạn có quyền yêu cầu xóa tài khoản và dữ liệu cá nhân bất kỳ lúc nào.';
      case 'Hỗ trợ & liên hệ':
        return 'Liên hệ với chúng tôi qua:\n\n'
            '📧 Email: support@chodocu.vn\n\n'
            '📞 Hotline: 1800 xxxx (miễn phí, 8h-22h)\n\n'
            '💬 Chat trực tiếp trong ứng dụng\n\n'
            '🌐 Website: www.chodocu.vn\n\n'
            'Thời gian phản hồi: trong vòng 24 giờ làm việc.';
      default:
        return 'Nội dung đang được cập nhật...';
    }
  }
}

// ---- Expandable item ----
class _ExpandableItem extends StatefulWidget {
  final String title;
  final List<String> children;
  const _ExpandableItem({required this.title, required this.children});

  @override
  State<_ExpandableItem> createState() => _ExpandableItemState();
}

class _ExpandableItemState extends State<_ExpandableItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A)),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_down
                      : Icons.chevron_right,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
        // Sub-items
        if (_expanded)
          ...widget.children.map((child) => _SubItem(label: child)),
      ],
    );
  }
}

// ---- Sub item ----
class _SubItem extends StatelessWidget {
  final String label;
  const _SubItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        InkWell(
          onTap: () {},
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(32, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
