import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/net_image.dart';
import '../../../models/address_model.dart';
import '../../../models/listing_model.dart';
import '../../../models/order_model.dart';
import '../../listing/services/address_service.dart';
import '../services/order_service.dart';

enum _PayMethod { cod, qr }

class CheckoutScreen extends StatefulWidget {
  final ListingModel listing;
  final int quantity;
  const CheckoutScreen({super.key, required this.listing, required this.quantity});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  _PayMethod _method = _PayMethod.cod;
  bool _placing = false;
  bool _loadingAddr = true;
  final _orderService = OrderService();
  final _addressService = AddressService();
  AddressModel? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    try {
      final list = await _addressService.getAll();
      if (!mounted) return;
      setState(() {
        _selectedAddress = list.firstWhere(
          (a) => a.isDefault,
          orElse: () => list.isNotEmpty ? list.first : AddressModel(id: -1, fullName: '', phoneNumber: '', street: '', district: '', city: '', isDefault: false),
        );
        if (_selectedAddress!.id == -1) _selectedAddress = null;
        _loadingAddr = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingAddr = false);
    }
  }

  Future<void> _changeAddress() async {
    final result = await context.push<AddressModel>('/address');
    if (result != null && mounted) {
      setState(() => _selectedAddress = result);
    }
  }

  double get _itemTotal => widget.listing.price * widget.quantity;
  double get _shippingFee => 0;
  double get _grandTotal => _itemTotal + _shippingFee;

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa chỉ nhận hàng')),
      );
      return;
    }
    setState(() => _placing = true);
    try {
      final order = await _orderService.createOrder(
        widget.listing.id,
        quantity: widget.quantity,
      );
      if (!mounted) return;
      final payLabel = _method == _PayMethod.cod
          ? 'Thanh toán khi nhận hàng'
          : 'Quét mã QR, chuyển khoản';
      // Gắn thêm address và payMethod vào order để hiển thị ở detail
      final enrichedOrder = OrderModel(
        id: order.id,
        status: order.status,
        totalAmount: order.totalAmount,
        quantity: order.quantity,
        createdAt: order.createdAt,
        listing: order.listing,
        seller: order.seller,
        shippingAddress: _selectedAddress!.fullAddress,
        payMethod: payLabel,
      );
      context.pushReplacement('/order-success', extra: {
        'order': enrichedOrder,
        'payMethod': payLabel,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A), size: 22),
          ),
        ),
        title: const Text('Thanh toán',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        children: [
          // ---- Địa chỉ ----
          _Card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Địa chỉ của bạn',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 6),
                      if (_loadingAddr)
                        const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondary))
                      else if (_selectedAddress == null)
                        const Text('Chưa có địa chỉ — nhấn Thêm để thêm mới',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))
                      else ...[
                        Text(_selectedAddress!.fullName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(_selectedAddress!.phoneNumber,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        const SizedBox(height: 2),
                        Text(_selectedAddress!.fullAddress,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _changeAddress,
                  child: Row(
                    children: const [
                      Icon(Icons.edit_outlined, size: 14, color: AppTheme.textSecondary),
                      SizedBox(width: 4),
                      Text('Thay đổi', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ---- Sản phẩm ----
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop name
                GestureDetector(
                  onTap: () => context.push('/partner/${l.seller.id}'),
                  child: Row(
                    children: [
                      Text(l.seller.fullName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 14, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
                const Divider(height: 16, color: Color(0xFFEEEEEE)),
                // Product row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: l.thumbnailUrl.isNotEmpty
                          ? NetImage(url: l.thumbnailUrl, width: 72, height: 72)
                          : Container(width: 72, height: 72,
                              color: const Color(0xFFEEEEEE),
                              child: const Icon(Icons.image, color: AppTheme.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.title,
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('x${widget.quantity}',
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                              Text(
                                '${FormatUtils.formatPrice(l.price * widget.quantity)}đ',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFEEEEEE)),

                // Chi tiết thanh toán
                const Text('Chi tiết thanh toán',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _PriceRow(label: 'Tổng tiền hàng',
                    value: '${FormatUtils.formatPrice(_itemTotal)}đ'),
                const SizedBox(height: 6),
                _PriceRow(label: 'Phí vận chuyển',
                    value: _shippingFee == 0 ? '0đ' : '${FormatUtils.formatPrice(_shippingFee)}đ'),
                const SizedBox(height: 10),
                _PriceRow(
                  label: 'Tổng tiền',
                  value: '${FormatUtils.formatPrice(_grandTotal)}đ',
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ---- Phương thức thanh toán ----
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Phương thức thanh toán',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _PayOption(
                  icon: Icons.payments_outlined,
                  label: 'Thanh toán khi nhận hàng',
                  value: _PayMethod.cod,
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v),
                ),
                const SizedBox(height: 10),
                _PayOption(
                  icon: Icons.credit_card_outlined,
                  label: 'Quét mã QR, chuyển khoản',
                  value: _PayMethod.qr,
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v),
                ),
              ],
            ),
          ),
        ],
      ),

      // ---- Bottom bar ----
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng thanh toán',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text(
                    '${FormatUtils.formatPrice(_grandTotal)} đ',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _placing ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  child: _placing
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('THANH TOÁN',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Helpers ----
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
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
    ),
    child: child,
  );
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _PriceRow({required this.label, required this.value, this.bold = false});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: bold ? const Color(0xFF1A1A1A) : AppTheme.textSecondary)),
      Text(value, style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: bold ? const Color(0xFF1A1A1A) : AppTheme.textSecondary)),
    ],
  );
}

class _PayOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final _PayMethod value, groupValue;
  final ValueChanged<_PayMethod> onChanged;
  const _PayOption({
    required this.icon, required this.label,
    required this.value, required this.groupValue, required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.secondary : const Color(0xFFDDDDDD),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF555555)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A))),
            ),
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppTheme.secondary : const Color(0xFFBBBBBB),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 9, height: 9,
                        decoration: const BoxDecoration(
                            color: AppTheme.secondary, shape: BoxShape.circle),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
