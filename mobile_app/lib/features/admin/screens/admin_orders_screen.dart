import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/admin_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _svc = AdminService();
  List<dynamic> _orders = [];
  int _total = 0, _page = 1;
  bool _loading = true;
  String? _statusFilter;

  // Khớp đúng với OrderStatus enum trong backend
  static const _statuses = [
    ('Pending', 'Chờ xác nhận', Colors.orange),
    ('Processing', 'Đang xử lý', Color(0xFF5C6BC0)),
    ('Shipping', 'Đang giao', Colors.blue),
    ('Delivered', 'Đã giao', AppTheme.secondary),
    ('Cancelled', 'Đã hủy', AppTheme.error),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) _page = 1;
    setState(() => _loading = true);
    try {
      final res = await _svc.getOrders(status: _statusFilter, page: _page);
      setState(() {
        if (reset || _page == 1) {
          _orders = res['items'] as List;
        } else {
          _orders = [..._orders, ...(res['items'] as List)];
        }
        _total = res['total'] as int;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildFilterBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              Text('$_total đơn hàng', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ]),
          ),
          Expanded(
            child: _loading && _orders.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : RefreshIndicator(
                    onRefresh: () => _load(reset: true),
                    color: AppTheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: _orders.length + (_orders.length < _total ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _orders.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: TextButton(
                                onPressed: () { _page++; _load(); },
                                child: const Text('Tải thêm')),
                          );
                        }
                        return _OrderCard(order: _orders[i]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip(null, 'Tất cả'),
              ..._statuses.map((s) => _chip(s.$1, s.$2)),
            ],
          ),
        ),
      );

  Widget _chip(String? val, String label) {
    final selected = _statusFilter == val;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () { setState(() => _statusFilter = val); _load(reset: true); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppTheme.primary : const Color(0xFFDDDDDD)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final o = order as Map<String, dynamic>;
    final status = o['status'].toString();
    final amount = (o['totalAmount'] as num).toDouble();
    final listing = o['listing'] as Map<String, dynamic>;
    final buyer = o['buyer'] as Map<String, dynamic>;
    final seller = o['seller'] as Map<String, dynamic>;
    final createdAt = DateTime.parse(o['createdAt']).toLocal();
    final dateStr =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

    Color sColor;
    String sLabel;
    IconData sIcon;
    switch (status) {
      case 'Pending':
        sColor = Colors.orange; sLabel = 'Chờ xác nhận'; sIcon = Icons.access_time_rounded; break;
      case 'Processing':
        sColor = const Color(0xFF5C6BC0); sLabel = 'Đang xử lý'; sIcon = Icons.inventory_2_outlined; break;
      case 'Shipping':
        sColor = Colors.blue; sLabel = 'Đang giao'; sIcon = Icons.local_shipping_outlined; break;
      case 'Delivered':
        sColor = AppTheme.secondary; sLabel = 'Đã giao'; sIcon = Icons.check_circle_outline; break;
      case 'Cancelled':
        sColor = AppTheme.error; sLabel = 'Đã hủy'; sIcon = Icons.cancel_outlined; break;
      default:
        sColor = AppTheme.textSecondary; sLabel = status; sIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text('#${o['id']}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                const SizedBox(width: 8),
                Text(dateStr, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: sColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sIcon, size: 12, color: sColor),
                      const SizedBox(width: 4),
                      Text(sLabel,
                          style: TextStyle(fontSize: 11, color: sColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 10),
            // Sản phẩm
            Text(listing['title'] ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(_fmtPrice(amount),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                const SizedBox(width: 8),
                Text('x${o['quantity']}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            // Người mua / bán
            Row(
              children: [
                _person(Icons.person_outline, 'Mua', buyer['fullName'] ?? ''),
                const SizedBox(width: 16),
                _person(Icons.store_outlined, 'Bán', seller['fullName'] ?? ''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _person(IconData icon, String role, String name) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 3),
          Text('$role: ', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          Text(name,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ],
      );

  String _fmtPrice(double p) {
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}M đ';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)}K đ';
    return '${p.toStringAsFixed(0)}đ';
  }
}
