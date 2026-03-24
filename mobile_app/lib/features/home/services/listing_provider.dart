import 'package:flutter/material.dart';
import '../../../models/listing_model.dart';
import 'listing_service.dart';

enum HomeTab { forYou, nearest, newest }

class _TabState {
  List<ListingModel> items = [];
  bool loading = false;
  bool hasMore = true;
  int page = 1;
  int total = 0;
}

class ListingProvider extends ChangeNotifier {
  final _service = ListingService();

  final _tabs = {
    HomeTab.forYou: _TabState(),
    HomeTab.nearest: _TabState(),
    HomeTab.newest: _TabState(),
  };

  // Search/filter list riêng (dùng cho SearchScreen & ProductScreen)
  List<ListingModel> _searchItems = [];
  bool _searchLoading = false;
  bool _searchHasMore = true;
  int _searchPage = 1;
  String? _searchKeyword;
  String? _searchCategory;
  double? _searchMinPrice;
  double? _searchMaxPrice;
  String? _searchCondition;
  String? _searchLocation;
  String? _searchSortBy;

  List<ListingModel> _favorites = [];
  bool _loadingFavorites = false;

  // Filters áp dụng cho home tabs
  String? _keyword;
  String? _category;
  double? _minPrice;
  double? _maxPrice;
  String? _location;
  String? _sortBy;

  // Getters home tabs
  List<ListingModel> tabListings(HomeTab tab) => _tabs[tab]!.items;
  bool tabLoading(HomeTab tab) => _tabs[tab]!.loading;
  bool tabHasMore(HomeTab tab) => _tabs[tab]!.hasMore;

  // Getters search
  List<ListingModel> get searchItems => _searchItems;
  bool get searchLoading => _searchLoading;
  bool get searchHasMore => _searchHasMore;
  String? get searchKeyword => _searchKeyword;
  String? get searchCategory => _searchCategory;
  double? get searchMinPrice => _searchMinPrice;
  double? get searchMaxPrice => _searchMaxPrice;
  String? get searchCondition => _searchCondition;
  String? get searchLocation => _searchLocation;
  String? get searchSortBy => _searchSortBy;

  // Compat getters (dùng bởi các màn hình cũ)
  List<ListingModel> get listings => _tabs[HomeTab.forYou]!.items;
  bool get loading => _tabs[HomeTab.forYou]!.loading;
  List<ListingModel> get favorites => _favorites;
  bool get loadingFavorites => _loadingFavorites;

  // ---- Home tabs ----
  Future<void> loadTab(HomeTab tab, {bool refresh = false}) async {
    final state = _tabs[tab]!;
    if (state.loading) return;
    if (refresh) {
      state.items = [];
      state.page = 1;
      state.hasMore = true;
    }
    if (!state.hasMore) return;

    state.loading = true;
    notifyListeners();

    try {
      final sortBy = _sortBy ?? switch (tab) {
        HomeTab.forYou => 'random',
        HomeTab.nearest => 'nearest',
        HomeTab.newest => 'newest',
      };
      final loc = tab == HomeTab.nearest ? _location : null;

      final result = await _service.getListings(
        keyword: _keyword,
        category: _category,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        location: loc,
        sortBy: sortBy,
        page: state.page,
      );
      final items = result['items'] as List<ListingModel>;
      final total = result['total'] as int;
      state.items.addAll(items);
      state.total = total;
      state.hasMore = state.items.length < total;
      state.page++;
    } catch (_) {
    } finally {
      state.loading = false;
      notifyListeners();
    }
  }

  Future<void> loadListings({bool refresh = false}) => loadTab(HomeTab.forYou, refresh: refresh);

  void setHomeFilters({
    String? keyword,
    String? category,
    double? minPrice,
    double? maxPrice,
  }) {
    _keyword = keyword;
    _category = category;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _refreshAllTabs();
  }

  void setFilters({String? keyword, String? category, double? minPrice, double? maxPrice, String? location, String? sortBy}) {
    _keyword = keyword;
    _category = category;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _sortBy = sortBy;
    _refreshAllTabs();
  }

  void setLocation(String? location) {
    _location = location;
    loadTab(HomeTab.nearest, refresh: true);
  }

  void _refreshAllTabs() {
    for (final tab in HomeTab.values) {
      loadTab(tab, refresh: true);
    }
  }

  // Search / Product screen ----
  Future<void> loadSearch({bool refresh = false}) async {
    if (_searchLoading) return;
    if (refresh) {
      _searchItems = [];
      _searchPage = 1;
      _searchHasMore = true;
    }
    if (!_searchHasMore) return;

    _searchLoading = true;
    notifyListeners();

    try {
      final result = await _service.getListings(
        keyword: _searchKeyword,
        category: _searchCategory,
        minPrice: _searchMinPrice,
        maxPrice: _searchMaxPrice,
        location: _searchLocation,
        condition: _searchCondition,
        sortBy: _searchSortBy ?? 'newest',
        page: _searchPage,
      );
      final items = result['items'] as List<ListingModel>;
      final total = (result['total'] as int?) ?? 0;
      _searchItems.addAll(items);
      _searchHasMore = _searchItems.length < total;
      _searchPage++;
    } catch (_) {
    } finally {
      _searchLoading = false;
      notifyListeners();
    }
  }

  void setSearchFilters({
    String? keyword,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? location,
    String? sortBy,
  }) {
    _searchKeyword = keyword;
    _searchCategory = category;
    _searchMinPrice = minPrice;
    _searchMaxPrice = maxPrice;
    _searchCondition = condition;
    _searchLocation = location;
    _searchSortBy = sortBy;
    loadSearch(refresh: true);
  }

  // ---- Favorites ----
  Future<void> toggleFavorite(int listingId) async {
    final isFav = await _service.toggleFavorite(listingId);
    for (final state in _tabs.values) {
      final idx = state.items.indexWhere((l) => l.id == listingId);
      if (idx != -1) state.items[idx].isFavorited = isFav;
    }
    final si = _searchItems.indexWhere((l) => l.id == listingId);
    if (si != -1) _searchItems[si].isFavorited = isFav;
    if (!isFav) _favorites.removeWhere((l) => l.id == listingId);
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    _loadingFavorites = true;
    notifyListeners();
    try {
      _favorites = await _service.getFavorites();
    } finally {
      _loadingFavorites = false;
      notifyListeners();
    }
  }
}
