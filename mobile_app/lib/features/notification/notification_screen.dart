import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/notification_model.dart';
import 'notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _service = NotificationService();
  List<NotificationModel> _all = [];
  bool _loading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await _service.getAll();
      setState(() {
        _all = res['items'] as List<NotificationModel>;
        _unreadCount = res['unreadCount'] as int;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    await _service.markAllRead();
    setState(() {
      _all = _all.map((n) => NotificationModel(
        id: n.id, title: n.title, body: n.body, type: n.type,
        isRead: true, actionUrl: n.actionUrl, createdAt: n.createdAt,
      )).toList();
      _unreadCount = 0;
    });
  }

  List<NotificationModel> get _activity =>
      _all.where((n) => n.type == 'Order' || n.type == 'System').toList();
  List<NotificationModel> get _news =>
      _all.where((n) => n.type == 'Promotion' || n.type == 'Chat').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_left,
                color: Color(0xFF1A1A1A), size: 22),
          ),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Thông báo',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A))),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Đọc tất cả',
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.secondary)),
            ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined,
                color: Color(0xFF1A1A1A), size: 24),
            onPressed: () => context.push('/cart'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: const Color(0xFF1A1A1A),
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15),
            unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400, fontSize: 15),
            indicatorColor: AppTheme.secondary,
            indicatorWeight: 2.5,
            tabs: const [Tab(text: 'Hoạt động'), Tab(text: 'Tin tức')],
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.secondary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.secondary,
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _NotifList(
                    items: _activity,
                    onTap: _onTap,
                    onDelete: _onDelete,
                  ),
                  _NotifList(
                    items: _news,
                    onTap: _onTap,
                    onDelete: _onDelete,
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _onTap(NotificationModel n) async {
    if (!n.isRead) {
      await _service.markRead(n.id);
      setState(() {
        final idx = _all.indexWhere((x) => x.id == n.id);
        if (idx >= 0) {
          _all[idx] = NotificationModel(
            id: n.id, title: n.title, body: n.body, type: n.type,
            isRead: true, actionUrl: n.actionUrl, createdAt: n.createdAt,
          );
          if (_unreadCount > 0) _unreadCount--;
        }
      });
    }
    if (n.actionUrl != null && mounted) context.push(n.actionUrl!);
  }

  Future<void> _onDelete(NotificationModel n) async {
    await _service.delete(n.id);
    setState(() => _all.removeWhere((x) => x.id == n.id));
  }
}

class _NotifList extends StatelessWidget {
  final List<NotificationModel> items;
  final Future<void> Function(NotificationModel) onTap;
  final Future<void> Function(NotificationModel) onDelete;
  const _NotifList(
      {required this.items, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Hiện tại chưa có thông báo nào.',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 14)),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
      itemBuilder: (_, i) {
        final n = items[i];
        return Dismissible(
          key: Key('notif_${n.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: AppTheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_outline,
                color: Colors.white, size: 22),
          ),
          onDismissed: (_) => onDelete(n),
          child: InkWell(
            onTap: () => onTap(n),
            child: Container(
              color: n.isRead ? Colors.white : const Color(0xFFF0FFF4),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_typeIcon(n.type),
                        color: AppTheme.secondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(n.title,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: n.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                      color: const Color(0xFF1A1A1A))),
                            ),
                            Text(_timeAgo(n.createdAt),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(n.body,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF555555),
                                height: 1.4)),
                      ],
                    ),
                  ),
                  if (!n.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4, left: 6),
                      decoration: const BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Order': return Icons.shopping_bag_outlined;
      case 'Chat': return Icons.chat_bubble_outline;
      case 'Promotion': return Icons.local_offer_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
