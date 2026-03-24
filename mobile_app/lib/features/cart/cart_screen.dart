import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_utils.dart';
import '../../core/widgets/net_image.dart';
import '../cart/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

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
        title: Consumer<CartProvider>(
          builder: (_, cart, __) => Text(
            'Giỏ hàng (${cart.totalCount})',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A)),
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 72, color: AppTheme.textSecondary),
                  SizedBox(height: 12),
                  Text('Giỏ hàng trống',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: cart.items.length,
                  itemBuilder: (_, i) {
                    final item = cart.items[i];
                    return _CartItemCard(
                      item: item,
                      onToggle: (v) =>
                          cart.toggleSelect(item.listing.id, v ?? false),
                      onQtyChange: (delta) =>
                          cart.updateQty(item.listing.id, item.quantity + delta),
                      onDelete: () => cart.removeItem(item.listing.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Chọn tất cả
                Row(
                  children: [
                    SizedBox(
                      width: 20, height: 20,
                      child: Checkbox(
                        value: cart.allSelected,
                        onChanged: (v) => cart.toggleSelectAll(v ?? false),
                        activeColor: AppTheme.secondary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        side: const BorderSide(
                            color: Color(0xFFBBBBBB), width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Tất cả',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                const Spacer(),
                // Tổng tiền
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Tổng cộng',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                    Text(
                      FormatUtils.formatPrice(cart.selectedTotal),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE53935)),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Nút mua
                GestureDetector(
                  onTap: cart.selectedCount > 0
                      ? () {
                          // Checkout với các item đã chọn
                          final selected = cart.selectedItems;
                          if (selected.length == 1) {
                            context.push('/checkout', extra: {
                              'listing': selected.first.listing,
                              'quantity': selected.first.quantity,
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Vui lòng chọn từng sản phẩm để thanh toán')),
                            );
                          }
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: cart.selectedCount > 0
                          ? AppTheme.secondary
                          : const Color(0xFFBBBBBB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Mua (${cart.selectedCount})',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final ValueChanged<bool?> onToggle;
  final void Function(int delta) onQtyChange;
  final VoidCallback onDelete;

  const _CartItemCard({
    required this.item,
    required this.onToggle,
    required this.onQtyChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = item.listing;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            SizedBox(
              width: 20, height: 20,
              child: Checkbox(
                value: item.selected,
                onChanged: onToggle,
                activeColor: AppTheme.secondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                side: const BorderSide(
                    color: Color(0xFFBBBBBB), width: 1.5),
              ),
            ),
            const SizedBox(width: 10),
            // Ảnh
            GestureDetector(
              onTap: () => context.push('/listing/${l.id}'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72, height: 72,
                  child: l.thumbnailUrl.isNotEmpty
                      ? NetImage(url: l.thumbnailUrl, width: 72, height: 72)
                      : Container(
                          color: const Color(0xFFEEEEEE),
                          child: const Icon(Icons.image,
                              color: AppTheme.textSecondary, size: 32)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(FormatUtils.formatPrice(l.price),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE53935))),
                  const SizedBox(height: 8),
                  // Qty control
                  Row(
                    children: [
                      _QtyBtn(
                          icon: Icons.remove,
                          onTap: () => onQtyChange(-1)),
                      Container(
                        width: 36, height: 28,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                                color: Color(0xFFDDDDDD)),
                          ),
                        ),
                        child: Text('${item.quantity}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                      _QtyBtn(
                          icon: Icons.add,
                          onTap: () => onQtyChange(1)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Xóa
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline,
                  size: 20, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14, color: AppTheme.textPrimary),
      ),
    );
  }
}
