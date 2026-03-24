import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../auth/services/auth_provider.dart';
import '../../notification/notification_provider.dart';
import '../services/listing_provider.dart';
import '../widgets/listing_card.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/filter_sheet.dart';
import 'search_screen.dart';
import '../../cart/cart_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedLocation = 'Chọn khu vực';
  FilterResult? _activeFilter;

  static const _tabs = [HomeTab.forYou, HomeTab.nearest, HomeTab.newest];
  static const _tabLabels = ['Dành cho bạn', 'Gần bạn', 'Mới nhất'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ListingProvider>();
      for (final tab in _tabs) {
        p.loadTab(tab, refresh: true);
      }
      // Fetch unread notifications nếu đã login
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        context.read<NotificationProvider>().fetchUnread();
      }
    });
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  bool get _hasFilter =>
      _activeFilter != null &&
      (_activeFilter!.category != null ||
          _activeFilter!.minPrice != null ||
          _activeFilter!.maxPrice != null ||
          _activeFilter!.condition != null);

  void _applyHomeFilter(FilterResult? f) {
    setState(() => _activeFilter = f);
    context.read<ListingProvider>().setHomeFilters(
      category: f?.category,
      minPrice: f?.minPrice,
      maxPrice: f?.maxPrice,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Consumer2<NotificationProvider, CartProvider>(
              builder: (_, notifProvider, cartProvider, __) => _HomeHeader(
                location: _selectedLocation,
                hasFilter: _hasFilter,
                unreadCount: context.read<AuthProvider>().isLoggedIn ? notifProvider.unreadCount : 0,
                cartCount: cartProvider.totalCount,
                onLocationTap: () => showLocationPicker(context,
                    onConfirm: (displayName, filterLocation) {
                  setState(() => _selectedLocation = displayName);
                  context.read<ListingProvider>().setLocation(filterLocation);
                }),
                onFilterTap: () async {
                  final result = await showFilterSheet(context, initial: _activeFilter);
                  if (result != null) _applyHomeFilter(result);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(child: _Banner()),
          if (_hasFilter)
            SliverToBoxAdapter(
              child: ActiveFilterBar(
                filter: _activeFilter!,
                onClear: () => _applyHomeFilter(null),
              ),
            ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(tabCtrl: _tabCtrl, tabs: _tabLabels),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: _tabs.map((tab) => _TabContent(tab: tab)).toList(),
        ),
      ),
    );
  }
}

// ---- Nội dung từng tab ----
class _TabContent extends StatefulWidget {
  final HomeTab tab;
  const _TabContent({required this.tab});

  @override
  State<_TabContent> createState() => _TabContentState();
}

class _TabContentState extends State<_TabContent> with AutomaticKeepAliveClientMixin {
  final _scrollCtrl = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<ListingProvider>();
    final items = provider.tabListings(widget.tab);
    final loading = provider.tabLoading(widget.tab);
    final hasMore = provider.tabHasMore(widget.tab);

    if (items.isEmpty && loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.secondary));
    }
    if (items.isEmpty && !loading) {
      return _emptyState(widget.tab);
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadTab(widget.tab, refresh: true),
      color: AppTheme.secondary,
      child: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => ListingCard(listing: items[i]),
                childCount: items.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.68,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.secondary),
                      ),
                    )
                  : hasMore
                      ? OutlinedButton.icon(
                          onPressed: () => provider.loadTab(widget.tab),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                          label: const Text('Tải thêm',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                            foregroundColor: AppTheme.secondary,
                            side: const BorderSide(color: AppTheme.secondary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22)),
                          ),
                        )
                      : const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text('Đã hiển thị tất cả sản phẩm',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(HomeTab tab) {
    final msg = tab == HomeTab.nearest
        ? 'Chọn khu vực để xem sản phẩm gần bạn'
        : 'Chưa có tin đăng nào';
    final icon = tab == HomeTab.nearest ? Icons.location_on_outlined : Icons.inbox_outlined;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

// ---- Header xanh lá ----
class _HomeHeader extends StatelessWidget {
  final String location;
  final bool hasFilter;
  final int unreadCount;
  final int cartCount;
  final VoidCallback onLocationTap;
  final VoidCallback onFilterTap;
  const _HomeHeader({
    required this.location,
    required this.hasFilter,
    required this.unreadCount,
    required this.cartCount,
    required this.onLocationTap,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)]),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onLocationTap,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AppLogo(size: 40),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (!context.read<AuthProvider>().isLoggedIn) {
                        context.go('/onboarding');
                        return;
                      }
                      context.push('/notifications');
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                        if (unreadCount > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      if (!context.read<AuthProvider>().isLoggedIn) {
                        context.go('/onboarding');
                        return;
                      }
                      context.push('/cart');
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 26),
                        if (cartCount > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Text(
                                cartCount > 99 ? '99+' : '$cartCount',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: _SearchBar(
                hasFilter: hasFilter,
                onFilterTap: onFilterTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Search bar ----
class _SearchBar extends StatefulWidget {
  final bool hasFilter;
  final VoidCallback onFilterTap;
  const _SearchBar({required this.hasFilter, required this.onFilterTap});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final q = _ctrl.text.trim();
    if (q.isNotEmpty) {
      context.go('/search?q=${Uri.encodeComponent(q)}');
    } else {
      context.go('/search');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onFilterTap,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: widget.hasFilter
                    ? AppTheme.secondary.withValues(alpha: 0.15)
                    : const Color(0xFFF0F0F0),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
              ),
              child: Icon(Icons.tune,
                  color: widget.hasFilter ? AppTheme.secondary : AppTheme.textSecondary,
                  size: 20),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
              decoration: const InputDecoration(
                hintText: 'Nhập để tìm kiếm',
                hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                isDense: true,
              ),
            ),
          ),
          GestureDetector(
            onTap: _submit,
            child: Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F0F0),
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
              ),
              child: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Banner slideshow ----
class _BannerSlide {
  final List<Color> colors;
  final String emoji;
  final String tag;
  final String title;
  final String subtitle;
  final String cta;
  final String route;
  const _BannerSlide({
    required this.colors,
    required this.emoji,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.route,
  });
}

const _bannerSlides = [
  _BannerSlide(
    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
    emoji: '♻️',
    tag: 'Sống xanh',
    title: 'Mua Cũ, Dùng Mới',
    subtitle: 'Tiết kiệm & bảo vệ môi trường',
    cta: 'Khám phá ngay',
    route: '/products',
  ),
  _BannerSlide(
    colors: [Color(0xFFE65100), Color(0xFFFF8C00)],
    emoji: '🔥',
    tag: 'Hot deal',
    title: 'Giảm Giá Sốc',
    subtitle: 'Hàng nghìn món đồ giá tốt mỗi ngày',
    cta: 'Xem ngay',
    route: '/search',
  ),
  _BannerSlide(
    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
    emoji: '📦',
    tag: 'Đăng tin miễn phí',
    title: 'Bán Đồ Cũ Dễ Dàng',
    subtitle: 'Chụp ảnh, đăng tin, nhận tiền ngay',
    cta: 'Đăng tin',
    route: '/camera',
  ),
];

class _Banner extends StatefulWidget {
  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> {
  final _pageCtrl = PageController();
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final next = (_current + 1) % _bannerSlides.length;
      _pageCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      _startAutoPlay();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      height: 160,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: _bannerSlides.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => _buildSlide(_bannerSlides[i]),
            ),
          ),
          // Dots
          Positioned(
            bottom: 10,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_bannerSlides.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i ? Colors.white : Colors.white.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_BannerSlide s) {
    return GestureDetector(
      onTap: () => context.go(s.route),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: s.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(right: -30, top: -30,
              child: Container(width: 130, height: 130,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), shape: BoxShape.circle))),
            Positioned(right: 40, bottom: -40,
              child: Container(width: 100, height: 100,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle))),
            Positioned(left: -20, bottom: -20,
              child: Container(width: 80, height: 80,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle))),
            // Emoji lớn bên phải
            Positioned(
              right: 16, top: 0, bottom: 0,
              child: Center(
                child: Text(s.emoji, style: const TextStyle(fontSize: 64)),
              ),
            ),
            // Nội dung bên trái
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 100, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s.tag,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  Text(s.title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900,
                          height: 1.2, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text(s.subtitle,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s.cta,
                        style: TextStyle(
                            color: s.colors.last,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Tab bar delegate ----
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabCtrl;
  final List<String> tabs;
  const _TabBarDelegate({required this.tabCtrl, required this.tabs});

  @override
  double get minExtent => 44;
  @override
  double get maxExtent => 44;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabCtrl,
        labelColor: AppTheme.textPrimary,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
        indicatorColor: AppTheme.secondary,
        indicatorWeight: 2.5,
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
