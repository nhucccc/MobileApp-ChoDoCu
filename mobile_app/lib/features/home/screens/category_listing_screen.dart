import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../services/listing_provider.dart';
import '../widgets/listing_card.dart';
import '../widgets/filter_sheet.dart';

const _sortOptions = [
  _SortOption('Mới nhất', 'newest'),
  _SortOption('Cũ nhất', 'oldest'),
  _SortOption('Giá cao nhất', 'price_desc'),
  _SortOption('Giá thấp nhất', 'price_asc'),
];

class _SortOption {
  final String label;
  final String value;
  const _SortOption(this.label, this.value);
}

class CategoryListingScreen extends StatefulWidget {
  final String? category;
  final String? keyword;
  const CategoryListingScreen({super.key, this.category, this.keyword});

  @override
  State<CategoryListingScreen> createState() => _CategoryListingScreenState();
}

class _CategoryListingScreenState extends State<CategoryListingScreen> {
  final _searchCtrl = TextEditingController();
  FilterResult? _filter;
  String _sortValue = 'newest';
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.keyword ?? '';
    if (widget.category != null) {
      _filter = FilterResult(category: widget.category);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<ListingProvider>().loadListings();
      }
    });  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _load() {
    context.read<ListingProvider>().setFilters(
      keyword: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      category: _filter?.category,
      minPrice: _filter?.minPrice,
      maxPrice: _filter?.maxPrice,
      location: _filter?.location,
      sortBy: _sortValue,
    );
  }

  Future<void> _openFilter() async {
    final result = await showFilterSheet(context, initial: _filter);
    if (result != null) {
      setState(() => _filter = result);
      _load();
    }
  }

  bool get _hasFilter =>
      _filter != null &&
      (_filter!.category != null ||
          _filter!.minPrice != null ||
          _filter!.maxPrice != null ||
          _filter!.condition != null ||
          _filter!.location != null);

  String get _title {
    if (widget.category != null) return widget.category!;
    if (_filter?.category != null) return _filter!.category!;
    if (widget.keyword != null && widget.keyword!.isNotEmpty) return widget.keyword!;
    return 'Tất cả';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListingProvider>();
    final total = provider.listings.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () => provider.loadListings(refresh: true),
        color: AppTheme.secondary,
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            // ---- Subheader: tiêu đề + số kết quả + filter + sort ----
            SliverToBoxAdapter(child: _buildSubHeader(total)),
            // ---- Grid sản phẩm ----
            if (provider.listings.isEmpty && !provider.loading)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary),
                      SizedBox(height: 12),
                      Text('Không tìm thấy sản phẩm',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => ListingCard(listing: provider.listings[i]),
                    childCount: provider.listings.length,
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
              child: provider.loading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.secondary, strokeWidth: 2)),
                    )
                  : const SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
          child: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A), size: 22),
        ),
        onPressed: () => context.pop(),
      ),
      titleSpacing: 0,
      title: Container(
        height: 38,
        margin: const EdgeInsets.only(right: 16),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Nhập để tìm kiếm',
            hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            suffixIcon: GestureDetector(
              onTap: _load,
              child: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
            ),
            isDense: true,
          ),
          onSubmitted: (_) => _load(),
        ),
      ),
    );
  }

  Widget _buildSubHeader(int total) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề + số kết quả
          Row(
            children: [
              Text(_title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              const SizedBox(width: 6),
              Text('($total kết quả)',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          // Filter + Sort row
          Row(
            children: [
              // Filter icon button
              GestureDetector(
                onTap: _openFilter,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: _hasFilter
                        ? AppTheme.secondary.withValues(alpha: 0.1)
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _hasFilter ? AppTheme.secondary : Colors.transparent,
                    ),
                  ),
                  child: Icon(Icons.tune,
                      size: 18,
                      color: _hasFilter ? AppTheme.secondary : AppTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 10),
              // Sort dropdown (overlay style)
              _SortDropdown(
                value: _sortValue,
                onChanged: (v) {
                  setState(() => _sortValue = v);
                  _load();
                },
              ),
              if (_hasFilter) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => _filter = null);
                    _load();
                  },
                  child: const Text('Xóa lọc',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.error, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Sort dropdown dạng overlay ----
class _SortDropdown extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _SortDropdown({required this.value, required this.onChanged});

  @override
  State<_SortDropdown> createState() => _SortDropdownState();
}

class _SortDropdownState extends State<_SortDropdown> {
  final _key = GlobalKey();
  OverlayEntry? _overlay;

  void _open() {
    final box = _key.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    _overlay = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close,
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 4,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Container(
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Text('Sắp xếp theo',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A))),
                      ),
                      ..._sortOptions.map((o) => _SortItem(
                            label: o.label,
                            selected: widget.value == o.value,
                            onTap: () {
                              _close();
                              widget.onChanged(o.value);
                            },
                          )),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _sortOptions.firstWhere((o) => o.value == widget.value);
    return GestureDetector(
      key: _key,
      onTap: _overlay == null ? _open : _close,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(current.label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _SortItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? AppTheme.secondary : const Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }
}
