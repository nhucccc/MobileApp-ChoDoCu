import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/net_image.dart';
import '../../../features/auth/services/auth_provider.dart';
import '../../../features/cart/cart_provider.dart';
import '../../../features/chat/services/chat_provider.dart';
import '../../../features/home/services/listing_provider.dart';
import '../../../features/home/services/listing_service.dart';
import '../../../features/home/widgets/listing_card.dart';
import '../../../models/listing_model.dart';
import '../widgets/video_player_web.dart';

class ListingDetailScreen extends StatefulWidget {
  final int id;
  const ListingDetailScreen({super.key, required this.id});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final _service = ListingService();
  ListingModel? _listing;
  List<ListingModel> _related = [];
  bool _loading = true;
  bool _contactingLoading = false;
  bool _relatedLoading = false;
  bool _relatedHasMore = true;
  int _relatedPage = 1;
  int _relatedTotal = 0;
  int _imgIndex = 0;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final l = await _service.getListing(widget.id);
      if (!mounted) return;
      setState(() {
        _listing = l;
        _loading = false;
        _qty = _qty.clamp(1, l.stock.clamp(1, 999));
      });
      // Load related sau khi đã set _listing
      _loadRelated(l.category, l.id, refresh: true);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadRelated(String category, int excludeId, {bool refresh = false}) async {
    if (_relatedLoading) return;
    if (refresh) {
      _relatedPage = 1;
      _relatedHasMore = true;
    }
    if (!_relatedHasMore) return;
    if (mounted) setState(() => _relatedLoading = true);
    try {
      final result = await _service.getListings(category: category, page: _relatedPage);
      if (!mounted) return;
      final items = (result['items'] as List<ListingModel>)
          .where((r) => r.id != excludeId)
          .toList();
      final total = (result['total'] as int?) ?? 0;
      setState(() {
        if (refresh) _related = items;
        else _related.addAll(items);
        _relatedTotal = total;
        _relatedPage++;
        _relatedHasMore = _related.length < (total > 0 ? total - 1 : 0);
        _relatedLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _relatedLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_listing == null) return;
    if (!context.read<AuthProvider>().isLoggedIn) {
      context.go('/onboarding');
      return;
    }
    // Dùng ListingProvider để cập nhật state toàn cục
    await context.read<ListingProvider>().toggleFavorite(_listing!.id);
    // Cập nhật local state
    setState(() => _listing!.isFavorited = !_listing!.isFavorited);
  }

  Future<void> _contactSeller() async {
    if (_listing == null) return;
    if (!context.read<AuthProvider>().isLoggedIn) {
      context.go('/onboarding');
      return;
    }
    setState(() => _contactingLoading = true);
    try {
      final convId = await context.read<ChatProvider>().startConversation(
        sellerId: _listing!.seller.id,
        listingId: _listing!.id,
        firstMessage: 'Xin chào, tôi quan tâm đến sản phẩm "${_listing!.title}"',
      );
      if (mounted) context.push('/chat/$convId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở chat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _contactingLoading = false);
    }
  }

  void _addToCart() {
    if (_listing == null) return;
    if (!context.read<AuthProvider>().isLoggedIn) {
      context.go('/onboarding');
      return;
    }
    context.read<CartProvider>().addItem(_listing!, qty: _qty);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã thêm vào giỏ hàng'),
        action: SnackBarAction(
          label: 'Xem giỏ',
          onPressed: () => context.push('/cart'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppTheme.secondary)));
    }
    if (_listing == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Không tìm thấy tin đăng')));
    }

    final l = _listing!;
    final auth = context.watch<AuthProvider>();
    final isOwner = auth.user?.id == l.seller.id;
    final cartCount = context.watch<CartProvider>().totalCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // ---- AppBar + ảnh ----
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6)
                    ],
                  ),
                  child: const Icon(Icons.chevron_left,
                      color: Color(0xFF1A1A1A), size: 24),
                ),
              ),
            ),
            title: const Text('Chi tiết sản phẩm',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A))),
            centerTitle: true,
            actions: [
              // Nút yêu thích
              GestureDetector(
                onTap: _toggleFavorite,
                child: Container(
                  width: 36, height: 36,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6)
                    ],
                  ),
                  child: Icon(
                    l.isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: l.isFavorited
                        ? AppTheme.error
                        : AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
              ),
              // Nút giỏ hàng với badge
              GestureDetector(
                onTap: () => context.push('/cart'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 36, height: 36,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6)
                        ],
                      ),
                      child: const Icon(Icons.shopping_cart_outlined,
                          color: AppTheme.textSecondary, size: 20),
                    ),
                    if (cartCount > 0)
                      Positioned(
                        right: 8, top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text('$cartCount',
                              style: const TextStyle(color: Colors.white, fontSize: 9),
                              textAlign: TextAlign.center),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    itemCount: l.imageUrls.isEmpty ? 1 : l.imageUrls.length,
                    onPageChanged: (i) => setState(() => _imgIndex = i),
                    itemBuilder: (_, i) => l.imageUrls.isEmpty
                        ? Container(
                            color: const Color(0xFFEEEEEE),
                            child: const Icon(Icons.image,
                                size: 80, color: AppTheme.textSecondary),
                          )
                        : NetImage(url: l.imageUrls[i], fit: BoxFit.cover),
                  ),
                  if (l.imageUrls.length > 1)
                    Positioned(
                      bottom: 10, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_imgIndex + 1}/${l.imageUrls.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ---- Tiêu đề + giá ----
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    '${FormatUtils.formatPrice(l.price)} VNĐ',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE53935)),
                  ),
                ],
              ),
            ),
          ),

          // ---- Tình trạng ----
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tình trạng: ${l.condition.isNotEmpty ? l.condition : 'Như mới (99%)'}',
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF1A1A1A)),
                ),
              ),
            ),
          ),

          // ---- Số lượng ----
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  const Text('Số lượng',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  // Hiển thị stock thật từ API
                  Text(
                    l.stock > 0 ? '${l.stock} còn hàng' : 'Hết hàng',
                    style: TextStyle(
                        fontSize: 13,
                        color: l.stock > 0
                            ? AppTheme.secondary
                            : AppTheme.error),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _StepBtn(
                        icon: Icons.remove,
                        onTap: () {
                          if (_qty > 1) setState(() => _qty--);
                        },
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text('$_qty',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                      _StepBtn(
                        icon: Icons.add,
                        onTap: () {
                          if (_qty < l.stock) setState(() => _qty++);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ---- Mô tả ----
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mô tả sản phẩm :',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    l.description.isNotEmpty
                        ? l.description
                        : 'Chưa có mô tả.',
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF444444),
                        height: 1.6),
                  ),
                ],
              ),
            ),
          ),

          // ---- Video sản phẩm ----
          if (l.videoUrl != null && l.videoUrl!.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Video sản phẩm',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    VideoPlayerWidget(url: l.videoUrl!),
                  ],
                ),
              ),
            ),

          // ---- Thông tin người bán ----
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin người bán',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.push('/partner/${l.seller.id}'),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFE0E0E0),
                          backgroundImage: l.seller.avatarUrl != null
                              ? netImageProvider(l.seller.avatarUrl!)
                              : null,
                          child: l.seller.avatarUrl == null
                              ? Text(
                                  l.seller.fullName[0].toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.seller.fullName,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '(${l.seller.rating.toStringAsFixed(1)})',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(width: 4),
                                  ...List.generate(
                                    5,
                                    (i) => Icon(
                                      i < l.seller.rating.floor()
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 14,
                                      color: i < l.seller.rating.floor()
                                          ? Colors.amber
                                          : const Color(0xFFDDDDDD),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (!isOwner) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _contactingLoading ? null : _contactSeller,
                            icon: _contactingLoading
                                ? const SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.chat_bubble_outline, size: 16),
                            label: const Text('Chat với người bán',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/partner/${l.seller.id}'),
                          icon: const Icon(Icons.storefront_outlined, size: 16),
                          label: const Text('Xem shop',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ---- Đề xuất mua hàng ----
          if (_related.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Đề xuất mua hàng',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ListingCard(listing: _related[i]),
                  childCount: _related.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.68,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _relatedLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.secondary),
                        ),
                      )
                    : _relatedHasMore
                        ? OutlinedButton.icon(
                            onPressed: () => _loadRelated(_listing!.category, _listing!.id),
                            icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                            label: const Text('Xem thêm',
                                style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 44),
                              foregroundColor: AppTheme.secondary,
                              side: const BorderSide(color: AppTheme.secondary),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22)),
                            ),
                          )
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('Đã hiển thị tất cả đề xuất',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                            ),
                          ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),

      // ---- Bottom bar ----
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: isOwner
              ? OutlinedButton(
                  onPressed: () async {
                    await context.push('/listing/${l.id}/edit');
                    // Reload lại data sau khi quay về từ edit
                    if (mounted) {
                      setState(() {
                        _loading = true;
                        _listing = null;
                      });
                      _load();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                  ),
                  child: const Text('Chỉnh sửa',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                )
              : Row(
                  children: [
                    // Thêm vào giỏ hàng
                    Expanded(
                      child: OutlinedButton(
                        onPressed: l.stock > 0 ? _addToCart : null,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          side: BorderSide(
                              color: l.stock > 0
                                  ? const Color(0xFFCCCCCC)
                                  : const Color(0xFFEEEEEE)),
                          foregroundColor: const Color(0xFF1A1A1A),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)),
                        ),
                        child: const Text('Thêm vào giỏ hàng',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Mua hàng ngay
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: l.stock > 0
                                ? [const Color(0xFF4CAF50), const Color(0xFF81D4FA)]
                                : [const Color(0xFFBBBBBB), const Color(0xFFBBBBBB)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: ElevatedButton(
                          onPressed: l.stock > 0
                              ? () {
                                  if (!context.read<AuthProvider>().isLoggedIn) {
                                    context.go('/onboarding');
                                    return;
                                  }
                                  context.push('/checkout', extra: {
                                    'listing': l,
                                    'quantity': _qty,
                                  });
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26)),
                          ),
                          child: Text(
                            l.stock > 0 ? 'Mua hàng ngay' : 'Hết hàng',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ---- Stepper button ----
class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCCCCCC)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF1A1A1A)),
      ),
    );
  }
}
