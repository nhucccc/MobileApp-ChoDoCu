import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _svc = AdminService();
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await _svc.getStats();
      if (mounted) setState(() { _stats = s; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Tổng quan hệ thống'),
                    const SizedBox(height: 12),
                    _buildGrid(),
                    const SizedBox(height: 20),
                    _sectionTitle('Hoạt động hôm nay'),
                    const SizedBox(height: 12),
                    _buildTodayRow(),
                    const SizedBox(height: 20),
                    _sectionTitle('Trạng thái đơn hàng'),
                    const SizedBox(height: 12),
                    _buildOrderStatus(),
                    const SizedBox(height: 20),
                    _sectionTitle('Rút tiền chờ duyệt'),
                    const SizedBox(height: 12),
                    _buildWithdrawalPending(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)));

  Widget _buildGrid() {
    final items = [
      _Stat('Người dùng', _n('totalUsers'), Icons.people_alt_outlined, const Color(0xFF5C6BC0)),
      _Stat('Tổng tin đăng', _n('totalListings'), Icons.inventory_2_outlined, const Color(0xFF26A69A)),
      _Stat('Đang bán', _n('activeListings'), Icons.storefront_outlined, AppTheme.secondary),
      _Stat('Tổng đơn hàng', _n('totalOrders'), Icons.shopping_bag_outlined, AppTheme.primary),
      _Stat('Chờ xử lý', _n('pendingOrders'), Icons.pending_actions_outlined, const Color(0xFFEF5350)),
      _Stat('Doanh thu', _money('totalRevenue'), Icons.account_balance_wallet_outlined, const Color(0xFF8D6E63)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: items.map(_statCard).toList(),
    );
  }

  Widget _statCard(_Stat s) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: s.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(s.icon, color: s.color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: s.color)),
                Text(s.label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      );

  Widget _buildTodayRow() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
        ),
        child: Row(
          children: [
            _todayItem(Icons.person_add_outlined, AppTheme.secondary,
                _n('newUsersToday'), 'Người dùng mới'),
          ],
        ),
      );

  Widget _todayItem(IconData icon, Color color, String val, String label) => Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      );

  Widget _buildOrderStatus() {
    final statuses = [
      ('pendingOrders', 'Chờ xác nhận', Colors.orange),
      ('processingOrders', 'Đang xử lý', const Color(0xFF5C6BC0)),
      ('shippingOrders', 'Đang giao', Colors.blue),
      ('deliveredOrders', 'Đã giao', AppTheme.secondary),
      ('cancelledOrders', 'Đã hủy', AppTheme.error),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        children: statuses.map((s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(s.$2, style: const TextStyle(fontSize: 13)),
              const Spacer(),
              Text(_n(s.$1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: s.$3)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  String _n(String key) => '${(_stats?[key] as num?)?.toInt() ?? 0}';
  String _money(String key) {
    final n = ((_stats?[key] as num?)?.toDouble()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }

  Widget _buildWithdrawalPending() {
    final count = (_stats?['pendingWithdrawals'] as num?)?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: count > 0 ? AppTheme.primary.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: count > 0 ? AppTheme.primary.withValues(alpha: 0.3) : const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count yêu cầu đang chờ',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: count > 0 ? AppTheme.primary : const Color(0xFF1A1A1A))),
                const Text('Cần xử lý trong tab Rút tiền',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          if (count > 0)
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: Center(
                child: Text('$count',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
}
