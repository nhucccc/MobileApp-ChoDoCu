import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/net_image.dart';
import '../../../features/auth/services/auth_provider.dart';
import '../../wallet/wallet_service.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _totalListings = 0;
  int _activeListings = 0;
  int _soldListings = 0;
  int _favoriteCount = 0;
  double _rating = 0;
  double _walletBalance = 0;
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      setState(() => _statsLoaded = true);
      return;
    }
    try {
      final api = ApiClient();
      final statsRes = await api.dio.get('/auth/me/stats');
      final balance = await WalletService().getBalance();
      if (mounted) {
        setState(() {
          _totalListings = (statsRes.data['totalListings'] as num?)?.toInt() ?? 0;
          _activeListings = (statsRes.data['activeListings'] as num?)?.toInt() ?? 0;
          _soldListings = (statsRes.data['soldListings'] as num?)?.toInt() ?? 0;
          _favoriteCount = (statsRes.data['favoriteCount'] as num?)?.toInt() ?? 0;
          _rating = (statsRes.data['rating'] as num?)?.toDouble() ?? 0;
          _walletBalance = balance;
          _statsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('loadStats error: $e');
      if (mounted) setState(() => _statsLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // ---- AppBar ----
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            automaticallyImplyLeading: false,
            leading: widget.userId != null
                ? IconButton(
                    icon: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
                      child: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A), size: 22),
                    ),
                    onPressed: () => context.pop(),
                  )
                : null,
            title: const Text('Tài khoản',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1A1A1A)),
                onPressed: () => context.push('/notifications'),
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1A1A1A)),
                onPressed: () => context.push('/cart'),
              ),
            ],
          ),

          // ---- Header: banner + avatar + info ----
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Banner
                Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4DD0E1), Color(0xFF26C6DA)],
                    ),
                  ),
                  child: Stack(children: [
                    Positioned(right: 16, top: 10, child: _Cloud(size: 90)),
                    Positioned(right: 90, top: 5, child: _Cloud(size: 55)),
                    Positioned(left: 20, top: 20, child: _Cloud(size: 65)),
                  ]),
                ),
                // White card below
                Container(
                  margin: const EdgeInsets.only(top: 80),
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                  child: Column(
                    children: [
                      // Name + username + email
                      Text(
                        user?.fullName.toUpperCase() ?? 'NGƯỜI DÙNG',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user?.phoneNumber ?? ''} ${user?.email ?? ''}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      // Stats row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: !_statsLoaded
                            ? const SizedBox(
                                height: 48,
                                child: Center(
                                  child: SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.secondary),
                                  ),
                                ),
                              )
                            : Row(
                                children: [
                                  _StatItem(
                                    value: '$_totalListings',
                                    label: 'Sản phẩm',
                                    onTap: () => context.push('/my-listings'),
                                  ),
                                  _divider(),
                                  _StatItem(
                                    value: '$_activeListings',
                                    label: 'Đang bán',
                                    onTap: () => context.push('/my-listings'),
                                  ),
                                  _divider(),
                                  _StatItem(
                                    value: '$_soldListings',
                                    label: 'Đã bán',
                                    onTap: () => context.push('/sales'),
                                  ),
                                  _divider(),
                                  _StatItem(
                                    value: '$_favoriteCount',
                                    label: 'Yêu thích',
                                    onTap: () => context.push('/favorites'),
                                  ),
                                  _divider(),
                                  _StatItem(
                                    value: _rating > 0
                                        ? _rating.toStringAsFixed(1)
                                        : '—',
                                    label: 'Đánh giá',
                                    icon: _rating > 0 ? Icons.star : null,
                                    iconColor: Colors.amber,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                // Avatar
                Positioned(
                  top: 40,
                  left: 0, right: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                      ),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: const Color(0xFFE0E0E0),
                        backgroundImage: user?.avatarUrl != null
                            ? netImageProvider(user!.avatarUrl!) : null,
                        child: user?.avatarUrl == null
                            ? Text(
                                (user?.fullName ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---- Số dư ví ----
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: () => context.push('/wallet'),
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 18, color: AppTheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Số dư ví: ${FormatUtils.formatPrice(_walletBalance)}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
          ),

          // ---- Menu groups ----
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              _MenuGroup(
                title: 'Mua hàng',
                icon: Icons.shopping_bag_outlined,
                items: [
                  _MenuItem(icon: Icons.receipt_long_outlined, label: 'Đơn hàng đã mua', onTap: () => context.push('/purchases')),
                  _MenuItem(icon: Icons.local_shipping_outlined, label: 'Chờ giao hàng', onTap: () {}),
                  _MenuItem(icon: Icons.sync_outlined, label: 'Đơn hàng đang xử lý', onTap: () {}),
                ],
              ),
              const SizedBox(height: 8),
              _MenuGroup(
                title: 'Bán hàng',
                icon: Icons.storefront_outlined,
                items: [
                  _MenuItem(icon: Icons.inventory_2_outlined, label: 'Sản phẩm của tôi', onTap: () => context.push('/my-listings')),
                  _MenuItem(icon: Icons.pending_outlined, label: 'Chờ xác nhận', onTap: () => context.push('/sales')),
                  _MenuItem(icon: Icons.trending_up_outlined, label: 'Đang xử lý', onTap: () {}),
                ],
              ),
              const SizedBox(height: 8),
              _MenuGroup(
                title: 'Tài Chính',
                icon: Icons.attach_money_outlined,
                items: [
                  _MenuItem(icon: Icons.account_balance_wallet_outlined, label: 'Rút Tiền', onTap: () => context.push('/wallet')),
                  _MenuItem(icon: Icons.history_outlined, label: 'Lịch sử', onTap: () => context.push('/wallet/history')),
                ],
              ),
              const SizedBox(height: 8),
              _MenuGroup(
                title: 'Trung tâm hỗ trợ',
                icon: Icons.support_agent_outlined,
                items: [
                  _MenuItem(icon: Icons.menu_book_outlined, label: 'Điều khoản và hướng dẫn', onTap: () => context.push('/terms')),
                  _MenuItem(icon: Icons.campaign_outlined, label: 'Đảm bảo cho người mua', onTap: () => context.push('/buyer-protection')),
                  _MenuItem(icon: Icons.lightbulb_outline, label: 'Đóng góp ý kiến', onTap: () => context.push('/feedback')),
                  _MenuItem(icon: Icons.phone_outlined, label: 'Liên hệ đến chúng tôi', onTap: () => context.push('/contact')),
                ],
              ),
              const SizedBox(height: 8),
              _MenuGroup(
                title: 'Tài khoản',
                icon: Icons.person_outline,
                items: [
                  _MenuItem(icon: Icons.verified_user_outlined, label: 'Xác minh danh tính', onTap: () => context.push('/identity-verification')),
                  _MenuItem(icon: Icons.manage_accounts_outlined, label: 'Hồ sơ của tôi', onTap: () => context.push('/profile/edit')),
                  _MenuItem(icon: Icons.settings_outlined, label: 'Cài đặt', onTap: () => context.push('/settings')),
                  _MenuItem(
                    icon: Icons.logout_outlined,
                    label: 'Đăng xuất',
                    onTap: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/login');
                    },
                    danger: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: const Color(0xFFEEEEEE));
}

// ---- Stat item ----
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  const _StatItem({required this.value, required this.label, this.icon, this.iconColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                if (icon != null) ...[
                  const SizedBox(width: 2),
                  Icon(icon, size: 12, color: iconColor ?? Colors.amber),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ---- Menu group ----
class _MenuGroup extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<_MenuItem> items;
  const _MenuGroup({required this.title, required this.icon, required this.items});

  @override
  State<_MenuGroup> createState() => _MenuGroupState();
}

class _MenuGroupState extends State<_MenuGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(widget.icon, size: 20, color: const Color(0xFF1A1A1A)),
                  const SizedBox(width: 10),
                  Text(widget.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    size: 20, color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // Items
          if (_expanded)
            ...widget.items.map((item) => _MenuItemTile(item: item)),
        ],
      ),
    );
  }
}

// ---- Menu item data ----
class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.danger = false});
}

// ---- Menu item tile ----
class _MenuItemTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Icon(item.icon, size: 18,
                color: item.danger ? AppTheme.error : AppTheme.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(item.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: item.danger ? AppTheme.error : const Color(0xFF1A1A1A),
                  )),
            ),
            Icon(Icons.chevron_right, size: 18,
                color: item.danger ? AppTheme.error : AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ---- Cloud widget ----
class _Cloud extends StatelessWidget {
  final double size;
  const _Cloud({required this.size});
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size * 0.6), painter: _CloudPainter());
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    final w = size.width; final h = size.height;
    final path = Path()
      ..addOval(Rect.fromCenter(center: Offset(w * 0.3, h * 0.6), width: w * 0.5, height: h * 0.7))
      ..addOval(Rect.fromCenter(center: Offset(w * 0.55, h * 0.45), width: w * 0.55, height: h * 0.85))
      ..addOval(Rect.fromCenter(center: Offset(w * 0.75, h * 0.65), width: w * 0.4, height: h * 0.6))
      ..addRect(Rect.fromLTRB(w * 0.1, h * 0.6, w * 0.9, h));
    canvas.drawPath(path, paint);
    // Smiley face
    final facePaint = Paint()..color = const Color(0xFFFFCC80)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.55, h * 0.42), h * 0.28, facePaint);
    final eyePaint = Paint()..color = Colors.brown..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.47, h * 0.35), h * 0.05, eyePaint);
    canvas.drawCircle(Offset(w * 0.63, h * 0.35), h * 0.05, eyePaint);
    final smilePaint = Paint()..color = Colors.brown..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawArc(Rect.fromCenter(center: Offset(w * 0.55, h * 0.44), width: h * 0.2, height: h * 0.15), 0.3, 2.5, false, smilePaint);
  }
  @override
  bool shouldRepaint(_) => false;
}
