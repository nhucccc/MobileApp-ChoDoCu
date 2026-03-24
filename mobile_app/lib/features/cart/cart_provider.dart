import 'package:flutter/material.dart';
import '../../models/listing_model.dart';

class CartItem {
  final ListingModel listing;
  int quantity;
  bool selected;

  CartItem({required this.listing, this.quantity = 1, this.selected = false});
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get selectedTotal => _items
      .where((i) => i.selected)
      .fold(0.0, (sum, i) => sum + i.listing.price * i.quantity);

  int get selectedCount => _items.where((i) => i.selected).length;

  bool get allSelected => _items.isNotEmpty && _items.every((i) => i.selected);

  void addItem(ListingModel listing, {int qty = 1}) {
    final idx = _items.indexWhere((i) => i.listing.id == listing.id);
    if (idx != -1) {
      _items[idx].quantity += qty;
    } else {
      _items.add(CartItem(listing: listing, quantity: qty));
    }
    notifyListeners();
  }

  void removeItem(int listingId) {
    _items.removeWhere((i) => i.listing.id == listingId);
    notifyListeners();
  }

  void updateQty(int listingId, int qty) {
    final idx = _items.indexWhere((i) => i.listing.id == listingId);
    if (idx != -1) {
      if (qty <= 0) {
        _items.removeAt(idx);
      } else {
        _items[idx].quantity = qty;
      }
      notifyListeners();
    }
  }

  void toggleSelect(int listingId, bool val) {
    final idx = _items.indexWhere((i) => i.listing.id == listingId);
    if (idx != -1) {
      _items[idx].selected = val;
      notifyListeners();
    }
  }

  void toggleSelectAll(bool val) {
    for (final item in _items) {
      item.selected = val;
    }
    notifyListeners();
  }

  List<CartItem> get selectedItems => _items.where((i) => i.selected).toList();

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
