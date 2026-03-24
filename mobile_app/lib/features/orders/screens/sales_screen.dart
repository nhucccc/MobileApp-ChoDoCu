import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../models/order_model.dart';
import '../services/order_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _service = OrderService();

  final _tabs = const [
    ('all', 'Tất cả'),
    ('Pending', 'Chờ xác nhận'),
    ('Processing', 'Đang xử lý'),
    ('Shipping', 'Đang giao'),
    ('Delivered', 'Hoàn tất'),
    ('Cancelled', 'Hủy'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
          'Đơn đặt hàng',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A)),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppTheme.secondary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.secondary,
          indicatorWeight: 2,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _tabs
            .map((t) => _SalesList(status: t.$1, service: _service))
            .toList(),
      ),
    );
  }
}

// ---- Tab content ----
class _SalesList extends StatefulWidget {
  final String status;
  final OrderService service;
  const _SalesList({required this.status, required this.service});

  @override
  State<_SalesList> createState() => _SalesListState();
}

class _SalesListState extends State<_SalesList>
    with AutomaticKeepAliveClientMixin {
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final orders = await widget.service.getSales(
          status: widget.status == 'all' ? null : widget.status);
      setState(() => _orders = orders);
    } catch (_) {
      setState(() => _error = 'Không thể tải đơn hàng');
    } finally {
      setState(() => _loading = false);
    }
  }

  // Xác nhận → chuyển sang trạng thái tiếp theo
  Future<void> _confirm(OrderModel order) async {
    final next = _nextStatus(order.status);
    if (next == null) return;

    final label = _nextLabel(order.status);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận đơn hàng'),
        content: Text('Chuyển đơn hàng sang "$label"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(label,
                  style: const TextStyle(color: AppTheme.secondary))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await widget.service.updateStatus(order.id, next);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể cập nhật trạng thái')));
      }
    }
  }

  String? _nextStatus(String current) {
    switch (current) {
      case 'Pending': return 'Processing';
      case 'Processing': return 'Shipping';
      default: return null;
    }
  }

  String _nextLabel(String current) {
    switch (current) {
      case 'Pending': return 'Xác nhận';
      case 'Processing': return 'Gửi hàng';
      default: return 'Xác nhận';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.secondary));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('Thử lại')),
        ]),
      );
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.storefront_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Chưa có đơn hàng nào',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.secondary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _SaleCard(
          order: _orders[i],
          onConfirm: _nextStatus(_orders[i].status) != null
              ? () => _confirm(_orders[i])
              : null,
          confirmLabel: _nextLabel(_orders[i].status),
        ),
      ),
    );
  }
}

// ---- Sale card ----
class _SaleCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onConfirm;
  final String confirmLabel;

  const _SaleCard({
    required this.order,
    this.onConfirm,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/order/${order.id}', extra: {'order': order, 'isBuyer': false}),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Header: buyer name + status ----
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Hiển thị tên buyer
                Row(children: [
                  Text(
                    order.buyer?.fullName ?? order.seller.fullName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      size: 16, color: AppTheme.textSecondary),
                ]),
                const Spacer(),
                Text(
                  _statusLabel(order.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(order.status),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // ---- Product row ----
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: order.listing.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            order.listing.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFEEEEEE),
                              child: const Icon(Icons.image,
                                  color: AppTheme.textSecondary),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFEEEEEE),
                            child: const Icon(Icons.image,
                                color: AppTheme.textSecondary),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A)),
                      ),
                      const SizedBox(height: 6),
                      Text('x${order.quantity}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                // Giá
                Text(
                  FormatUtils.formatPrice(order.listing.price),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
          ),

          // ---- Tổng ----
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Tổng: ${FormatUtils.formatPrice(order.totalAmount)}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
          ),

          // ---- Action ----
          if (onConfirm != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: onConfirm,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondary,
                      side: const BorderSide(color: AppTheme.secondary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                    ),
                    child: Text(confirmLabel,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Pending': return 'Đơn hàng đặt';
      case 'Processing': return 'Đang xử lý';
      case 'Shipping': return 'Đơn hàng đang giao';
      case 'Delivered': return 'Hoàn tất';
      case 'Returned': return 'Trả hàng';
      case 'Cancelled': return 'Đơn hàng đã bị hủy';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered': return AppTheme.secondary;
      case 'Cancelled': return AppTheme.error;
      case 'Pending': return Colors.orange;
      case 'Shipping': return Colors.blue;
      default: return AppTheme.textSecondary;
    }
  }
}
