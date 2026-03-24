import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../models/order_model.dart';
import '../services/order_service.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _service = OrderService();

  final _tabs = const [
    ('all', 'Tất cả'),
    ('Pending', 'Chờ xử lý'),
    ('Processing', 'Đang xử lý'),
    ('Shipping', 'Chờ giao hàng'),
    ('Delivered', 'Đã giao'),
    ('Returned', 'Trả hàng'),
    ('Cancelled', 'Hủy hàng'),
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
          'Đơn mua của bạn',
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
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _tabs
            .map((t) => _OrderList(
                  status: t.$1,
                  service: _service,
                ))
            .toList(),
      ),
    );
  }
}

// ---- Tab content ----
class _OrderList extends StatefulWidget {
  final String status;
  final OrderService service;
  const _OrderList({required this.status, required this.service});

  @override
  State<_OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<_OrderList>
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
      final orders = await widget.service.getPurchases(
          status: widget.status == 'all' ? null : widget.status);
      setState(() => _orders = orders);
    } catch (e) {
      setState(() => _error = 'Không thể tải đơn hàng');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmReceived(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận đã nhận hàng'),
        content: const Text('Bạn xác nhận đã nhận được hàng? Tiền sẽ được chuyển cho người bán.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Chưa nhận')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đã nhận hàng',
                  style: TextStyle(color: AppTheme.secondary))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await widget.service.confirmReceived(order.id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã xác nhận nhận hàng'),
              backgroundColor: AppTheme.success));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xác nhận')));
      }
    }
  }

  Future<void> _cancel(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: const Text('Bạn có chắc muốn hủy đơn hàng này không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hủy đơn',
                  style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await widget.service.cancelOrder(order.id);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể hủy đơn hàng')));
      }
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
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Chưa có đơn hàng nào',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14)),
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
        itemBuilder: (_, i) => _OrderCard(
          order: _orders[i],
          onCancel: _orders[i].canCancel ? () => _cancel(_orders[i]) : null,
          onConfirmReceived: _orders[i].status == 'Shipping'
              ? () => _confirmReceived(_orders[i])
              : null,
          onBuyAgain: () => context.push('/listing/${_orders[i].listing.id}'),
        ),
      ),
    );
  }
}

// ---- Order card ----
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirmReceived;
  final VoidCallback onBuyAgain;

  const _OrderCard({
    required this.order,
    this.onCancel,
    this.onConfirmReceived,
    required this.onBuyAgain,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/order/${order.id}', extra: {'order': order, 'isBuyer': true}),
      borderRadius: BorderRadius.circular(12),
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
          // ---- Header: seller + status ----
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      context.push('/partner/${order.seller.id}'),
                  child: Row(
                    children: [
                      Text(
                        order.seller.fullName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          size: 16, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  order.statusLabel,
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
                      Text(
                        'x${order.quantity}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary),
                      ),
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

          // ---- Actions ----
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onConfirmReceived != null) ...[
                  ElevatedButton(
                    onPressed: onConfirmReceived,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Đã nhận hàng',
                        style: TextStyle(fontSize: 13)),
                  ),
                ] else if (onCancel != null) ...[
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                    ),
                    child: const Text('Hủy đơn',
                        style: TextStyle(fontSize: 13)),
                  ),
                ] else ...[
                  OutlinedButton(
                    onPressed: onBuyAgain,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondary,
                      side: const BorderSide(color: AppTheme.secondary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                    ),
                    child: const Text('Mua lại',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ), // end Container
    ); // end InkWell
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
