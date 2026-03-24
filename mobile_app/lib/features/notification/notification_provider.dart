import 'package:flutter/material.dart';
import 'notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final _service = NotificationService();
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  Future<void> fetchUnread() async {
    try {
      final res = await _service.getAll(page: 1);
      _unreadCount = res['unreadCount'] as int;
      notifyListeners();
    } catch (_) {}
  }

  void decrement() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  void reset() {
    _unreadCount = 0;
    notifyListeners();
  }
}
