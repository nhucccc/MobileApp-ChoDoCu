import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../services/listing_provider.dart';
import '../widgets/listing_card.dart';
import '../widgets/filter_sheet.dart';

class SearchScreen extends StatefulWidget {
  final String? initialKeyword;
  final String? initialCategory;
  const SearchScreen({super.key, this.initialKeyword, this.initialCategory});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _searchCtrl;
  FilterResult? _filter;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialKeyword ?? '');
    if (widget.initialCategory != null) {
      _filter = FilterResult(category: widget.initialCategory);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    context.read<ListingProvider>().setSearchFilters(
      keyword: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      category: _filter?.category,
      minPrice: _filter?.minPrice,
      maxPrice: _filter?.maxPrice,
      condition: _filter?.condition,
      location: _filter?.location,
      sortBy: _filter?.sortBy,
    );
  }

  Future<void> _openFilter() async {
    final result = await showFilterSheet(context, initial: _filter);
    if (result != null) {
      setState(() => _filter = result);
      _search();
    }
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
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: widget.initialKeyword == null && widget.initialCategory == null,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm sản phẩm...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
          ),
          onSubmitted: (_) => _search(),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.tune,
                    color: _hasFilter ? AppTheme.secondary : AppTheme.textSecondary),
                onPressed: _openFilter,
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
        ],
      ),
      body: Column(
        children: [
          if (_hasFilter)
            ActiveFilterBar(
              filter: _filter!,
              onClear: () {
                setState(() => _filter = null);
                _search();
              },
            ),
          Expanded(
            child: items.isEmpty && loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
                : items.isEmpty && !loading
                    ? const Center(
                        child: Text('Không tìm thấy kết quả',
                            style: TextStyle(color: AppTheme.textSecondary)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, i) => ListingCard(listing: items[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

// ---- Thanh filter active (dùng chung) ----
class ActiveFilterBar extends StatelessWidget {
  final FilterResult filter;
  final VoidCallback onClear;
  const ActiveFilterBar({super.key, required this.filter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (filter.sortBy != null) {
      const labels = {
        'newest': 'Mới nhất', 'oldest': 'Cũ nhất',
        'price_asc': 'Giá thấp nhất', 'price_desc': 'Giá cao nhất',
      };
      chips.add(labels[filter.sortBy] ?? filter.sortBy!);
    }
    if (filter.category != null) chips.add(filter.category!);
    if (filter.condition != null) chips.add(filter.condition!);
    if (filter.location != null) chips.add(filter.location!);
    if (filter.minPrice != null || filter.maxPrice != null) {
      final min = filter.minPrice != null ? '${(filter.minPrice! / 1000).toStringAsFixed(0)}k' : '0';
      final max = filter.maxPrice != null ? '${(filter.maxPrice! / 1000).toStringAsFixed(0)}k' : '∞';
      chips.add('$min – $max đ');
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips
                    .map((c) => Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.4)),
                          ),
                          child: Text(c,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.secondary,
                                  fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('Xóa',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.error, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
