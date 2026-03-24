import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../services/listing_provider.dart';
import '../widgets/listing_card.dart';
import '../widgets/filter_sheet.dart';
import 'search_screen.dart';

// Icon + màu tương ứng với AppConstants.categories
const _catIcons = <IconData>[
  Icons.checkroom_outlined,        // Thời trang nam
  Icons.woman_outlined,            // Thời trang nữ
  Icons.menu_book_outlined,        // Sách
  Icons.toys_outlined,             // Đồ chơi
  Icons.sports_basketball_outlined,// Đồ thể thao
  Icons.kitchen_outlined,          // Đồ gia dụng
  Icons.phone_android_outlined,    // Điện thoại & máy tính
  Icons.directions_bike_outlined,  // Xe cộ
  Icons.electrical_services_outlined, // Đồ điện gia dụng
  Icons.face_retouching_natural_outlined, // Mỹ phẩm
  Icons.home_outlined,             // Nhà cửa
  Icons.category_outlined,         // Khác
];

const _catColors = <Color>[
  Color(0xFF1A1A2E),
  Color(0xFF6A0572),
  Color(0xFF7B3F00),
  Color(0xFFFF6B6B),
  Color(0xFFFF8C00),
  Color(0xFF4A90D9),
  Color(0xFF2C2C2C),
  Color(0xFF0D0D0D),
  Color(0xFF888888),
  Color(0xFFE91E8C),
  Color(0xFF4CAF50),
  Color(0xFF9E9E9E),
];

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  FilterResult? _filter;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListingProvider>().setSearchFilters();
    });
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<ListingProvider>().loadSearch();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _applyFilter(FilterResult? f) {
    setState(() => _filter = f);
    context.read<ListingProvider>().setSearchFilters(
      category: f?.category,
      minPrice: f?.minPrice,
      maxPrice: f?.maxPrice,
      condition: f?.condition,
      location: f?.location,
      sortBy: f?.sortBy,
    );
  }

  bool get _hasFilter =>
      _filter != null &&
      (_filter!.category != null ||
          _filter!.minPrice != null ||
          _filter!.maxPrice != null ||
          _filter!.condition != null ||
          _filter!.location != null ||
          _filter!.sortBy != null);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListingProvider>();
    final items = provider.searchItems;
    final loading = provider.searchLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Sản phẩm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        centerTitle: true,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.tune,
                    color: _hasFilter ? AppTheme.secondary : AppTheme.textSecondary),
                onPressed: () async {
                  final result = await showFilterSheet(context, initial: _filter);
                  if (result != null) _applyFilter(result);
                },
              ),
              if (_hasFilter)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: AppTheme.secondary, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.textSecondary),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadSearch(refresh: true),
        color: AppTheme.secondary,
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            // ---- Danh mục ----
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Danh mục',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      children: [
                        // Ô "Tất cả" đầu tiên
                        _CatItem(
                          name: 'Tất cả',
                          icon: Icons.grid_view_rounded,
                          color: const Color(0xFFBBBBBB),
                          selected: _filter?.category == null,
                          onTap: () => _applyFilter(null),
                        ),
                        // Các danh mục từ AppConstants
                        ...List.generate(AppConstants.categories.length, (i) {
                          final name = AppConstants.categories[i];
                          final icon = i < _catIcons.length ? _catIcons[i] : Icons.category_outlined;
                          final color = i < _catColors.length ? _catColors[i] : const Color(0xFF9E9E9E);
                          return _CatItem(
                            name: name,
                            icon: icon,
                            color: color,
                            selected: _filter?.category == name,
                            onTap: () => _applyFilter(FilterResult(category: name)),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // ---- Filter bar ----
            if (_hasFilter)
              SliverToBoxAdapter(
                child: ActiveFilterBar(
                  filter: _filter!,
                  onClear: () => _applyFilter(null),
                ),
              ),
            // ---- Header sản phẩm ----
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _filter?.category != null
                          ? _filter!.category!
                          : 'Tất cả sản phẩm',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (loading)
                      const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondary)),
                  ],
                ),
              ),
            ),
            // ---- Grid sản phẩm ----
            if (items.isEmpty && !loading)
              const SliverFillRemaining(
                child: Center(
                  child: Text('Không có sản phẩm nào',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
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
          ],
        ),
      ),
    );
  }
}

class _CatItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _CatItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.secondary.withValues(alpha: 0.15)
                  : color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppTheme.secondary : color.withValues(alpha: 0.25),
                width: selected ? 2 : 1.5,
              ),
            ),
            child: Icon(icon,
                color: selected ? AppTheme.secondary : color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? AppTheme.secondary : const Color(0xFF1A1A1A),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
