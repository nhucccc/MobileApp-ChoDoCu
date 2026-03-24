import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/net_image.dart';
import '../../../models/order_model.dart';
import '../services/order_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  final bool isBuyer;
  const OrderDetailScreen({super.key, required this.order, this.isBuyer = true});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderModel _order;
  bool _cancelling = false;
  bool _confirming = false;
  final _service = OrderService();

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    if (ok != true) return;
    setState(() => _cancelling = true);
    try {
      await _service.cancelOrder(_order.id);
      setState(() => _order = OrderModel(
            id: _order.id,
            status: 'Cancelled',
            totalAmount: _order.totalAmount,
            quantity: _order.quantity,
            createdAt: _order.createdAt,
            listing: _order.listing,
            seller: _order.seller,
            shippingAddress: _order.shippingAddress,
            payMethod: _order.payMethod,
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đã hủy đơn hàng'),
            backgroundColor: AppTheme.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _confirmReceived() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    if (ok != true) return;
    setState(() => _confirming = true);
    try {
      await _service.confirmReceived(_order.id);
      setState(() => _order = OrderModel(
            id: _order.id,
            status: 'Delivered',
            totalAmount: _order.totalAmount,
            quantity: _order.quantity,
            createdAt: _order.createdAt,
            listing: _order.listing,
            seller: _order.seller,
            shippingAddress: _order.shippingAddress,
            payMethod: _order.payMethod,
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đã xác nhận nhận hàng. Tiền đã chuyển cho người bán.'),
            backgroundColor: AppTheme.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    final l = o.listing;
    final createdAt = o.createdAt.toLocal();
    final timeStr =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} '
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
                color: Color(0xFFF0F0F0), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_left,
                color: Color(0xFF1A1A1A), size: 22),
          ),
        ),
        title: const Text('Chi tiết đơn hàng',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A))),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text('Mã: #${o.id}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 100),
        children: [
          // ---- Trạng thái đơn hàng ----
          _Card(
            child: Column(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: _statusColor(o.status).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_statusIcon(o.status),
                      color: _statusColor(o.status), size: 32),
                ),
                const SizedBox(height: 10),
                Text(o.statusLabel,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Mã đơn hàng: #${o.id}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text('Đặt lúc: $timeStr',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ---- Sản phẩm ----
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront_outlined,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(o.seller.fullName,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/partner/${o.seller.id}'),
                      child: const Text('Xem shop',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.secondary)),
                    ),
                  ],
                ),
                const Divider(height: 16, color: Color(0xFFEEEEEE)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: l.thumbnailUrl.isNotEmpty
                          ? NetImage(url: l.thumbnailUrl, width: 72, height: 72)
                          : Container(
                              width: 72, height: 72,
                              color: const Color(0xFFEEEEEE),
                              child: const Icon(Icons.image,
                                  color: AppTheme.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('x${o.quantity}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary)),
                              Text(
                                '${FormatUtils.formatPrice(l.price)}đ',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFE53935)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _StatusBadge(status: o.status),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ---- Địa chỉ nhận hàng ----
          _Card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_outlined,
                      size: 16, color: AppTheme.secondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Địa chỉ nhận hàng',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        o.shippingAddress ?? 'Chưa có địa chỉ',
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ---- Thông tin thanh toán ----
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thông tin thanh toán',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _Row(label: 'Phương thức',
                    value: o.payMethod ?? 'Thanh toán khi nhận hàng'),
                const SizedBox(height: 8),
                _Row(label: 'Tạm tính',
                    value: '${FormatUtils.formatPrice(o.totalAmount)}đ'),
                const SizedBox(height: 8),
                _Row(label: 'Phí vận chuyển', value: 'Miễn phí'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Color(0xFFEEEEEE), height: 1),
                ),
                _Row(
                  label: 'Tổng thanh toán',
                  value: '${FormatUtils.formatPrice(o.totalAmount)}đ',
                  bold: true,
                  valueColor: const Color(0xFFE53935),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ---- Ghi chú ----
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.secondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppTheme.secondary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chỉ thanh toán khi bạn đã kiểm tra và nhận được sản phẩm. Liên hệ người bán nếu có vấn đề.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondary,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ---- Bottom buttons ----
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isBuyer) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/conversations'),
                    icon: const Icon(Icons.chat_bubble_outline,
                        size: 18, color: Colors.white),
                    label: const Text('Chat với người bán',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26)),
                    ),
                  ),
                ),
                if (o.status == 'Shipping') ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _confirming ? null : _confirmReceived,
                      icon: _confirming
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline,
                              size: 18, color: Colors.white),
                      label: const Text('Xác nhận đã nhận hàng',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26)),
                      ),
                    ),
                  ),
                ],
                if (o.canCancel) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _cancelling ? null : _cancel,
                      icon: _cancelling
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppTheme.error))
                          : const Icon(Icons.cancel_outlined,
                              size: 18, color: AppTheme.error),
                      label: const Text('Hủy đơn hàng',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26)),
                      ),
                    ),
                  ),
                ],
              ] else ...[
                // Seller view: xem thông tin người mua
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final buyerId = o.buyer?.id ?? o.seller.id;
                      context.push('/partner/$buyerId');
                    },
                    icon: const Icon(Icons.person_outline,
                        size: 18, color: AppTheme.secondary),
                    label: const Text('Xem thông tin người mua',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.secondary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending': return AppTheme.secondary;
      case 'Processing': return Colors.orange;
      case 'Shipping': return Colors.blue;
      case 'Delivered': return AppTheme.secondary;
      case 'Cancelled': return AppTheme.error;
      default: return AppTheme.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Pending': return Icons.access_time_rounded;
      case 'Processing': return Icons.inventory_2_outlined;
      case 'Shipping': return Icons.local_shipping_outlined;
      case 'Delivered': return Icons.check_circle_outline_rounded;
      case 'Cancelled': return Icons.cancel_outlined;
      default: return Icons.receipt_long_outlined;
    }
  }
}

// ---- Widgets ----
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))
          ],
        ),
        child: child,
      );
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? valueColor;
  const _Row({required this.label, required this.value, this.bold = false, this.valueColor});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  color: bold ? const Color(0xFF1A1A1A) : AppTheme.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  color: valueColor ?? (bold ? const Color(0xFF1A1A1A) : AppTheme.textSecondary))),
        ],
      );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (status) {
      case 'Pending': bg = AppTheme.secondary; label = 'Chờ xác nhận'; break;
      case 'Processing': bg = Colors.orange; label = 'Đang xử lý'; break;
      case 'Shipping': bg = Colors.blue; label = 'Đang giao'; break;
      case 'Delivered': bg = AppTheme.secondary; label = 'Đã giao'; break;
      case 'Cancelled': bg = AppTheme.error; label = 'Đã hủy'; break;
      default: bg = AppTheme.textSecondary; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: bg)),
    );
  }
}
