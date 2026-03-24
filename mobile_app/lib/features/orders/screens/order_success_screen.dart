import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../models/order_model.dart';

class OrderSuccessScreen extends StatelessWidget {
  final OrderModel order;
  final String payMethod;
  const OrderSuccessScreen({
    super.key,
    required this.order,
    required this.payMethod,
  });

  @override
  Widget build(BuildContext context) {
    final o = order;
    final l = o.listing;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                children: [
                  Center(
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded,
                          color: AppTheme.secondary, size: 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('Dat hang thanh cong!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text('Ma don hang: #${o.id}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(height: 28),
                  _Card(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: l.thumbnailUrl.isNotEmpty
                              ? CachedNetworkImage(imageUrl: l.thumbnailUrl, width: 72, height: 72, fit: BoxFit.cover)
                              : Container(width: 72, height: 72, color: const Color(0xFFEEEEEE),
                                  child: const Icon(Icons.image, color: AppTheme.textSecondary)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('x${o.quantity}',
                                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                  Text('${FormatUtils.formatPrice(o.totalAmount)}d',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFE53935))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Card(
                    child: Column(
                      children: [
                        _InfoRow(icon: Icons.location_on_outlined, label: 'Dia chi nhan', value: o.shippingAddress ?? 'Chua co dia chi'),
                        const Divider(height: 16, color: Color(0xFFEEEEEE)),
                        _InfoRow(icon: Icons.payments_outlined, label: 'Thanh toan', value: payMethod),
                        const Divider(height: 16, color: Color(0xFFEEEEEE)),
                        _InfoRow(icon: Icons.receipt_long_outlined, label: 'Tong tien',
                            value: '${FormatUtils.formatPrice(o.totalAmount)}d',
                            valueColor: const Color(0xFFE53935), bold: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: () => context.push('/order/${o.id}', extra: {'order': o}),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary, elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        child: const Text('Xem chi tiet don hang',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: OutlinedButton(
                        onPressed: () => context.go('/'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFDDDDDD)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        child: const Text('Tiep tuc mua sam',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
    ),
    child: child,
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool bold;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.bold = false, this.valueColor});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: AppTheme.textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ?? const Color(0xFF1A1A1A))),
          ],
        ),
      ),
    ],
  );
}
