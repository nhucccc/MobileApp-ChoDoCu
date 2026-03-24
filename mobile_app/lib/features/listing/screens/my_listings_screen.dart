import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/net_image.dart';
import '../../../models/listing_model.dart';
import '../../home/services/listing_service.dart';
import '../../auth/services/auth_provider.dart';
import 'package:provider/provider.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _service = ListingService();
  List<ListingModel> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    try {
      final items = await _service.getUserListings(auth.user!.id);
      setState(() {
        _all = items;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<ListingModel> get _filtered {
    switch (_tab.index) {
      case 1:
        return _all.where((l) => l.status == 'Active').toList();
      case 2:
        return _all.where((l) => l.status == 'Sold').toList();
      default:
        return _all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F0F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A), size: 22),
          ),
        ),
        title: const Text('Sản phẩm của tôi',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined, color: Color(0xFF1A1A1A), size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF1A1A1A), size: 22),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ---- Tab bar ----
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: _TabBar(
              controller: _tab,
              all: _all.length,
              active: _all.where((l) => l.status == 'Active').length,
              sold: _all.where((l) => l.status == 'Sold').length,
            ),
          ),
          // ---- List ----
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
                : _filtered.isEmpty
                    ? _empty()
                    : _buildList(_filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<ListingModel> items) {
    // Group by status label
    final groups = <String, List<ListingModel>>{};
    for (final l in items) {
      final label = _statusLabel(l.status);
      groups.putIfAbsent(label, () => []).add(l);
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.secondary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Text(entry.key,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF888888))),
            ),
            ...entry.value.map((l) => _ListingCard(
                  listing: l,
                  onEdit: () => context.push('/listing/${l.id}/edit').then((_) => _load()),
                  onDelete: () => _confirmDelete(l),
                )),
          ],
        ],
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Chưa có sản phẩm nào',
                style: TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/camera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Đăng tin ngay', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

  Future<void> _confirmDelete(ListingModel l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa tin đăng'),
        content: Text('Xóa "${l.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.deleteListing(l.id);
    _load();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Active':
        return 'Đang bán';
      case 'Sold':
        return 'Đã bán';
      case 'Hidden':
        return 'Đã ẩn';
      default:
        return status;
    }
  }
}

// ---- Custom tab bar ----
class _TabBar extends StatelessWidget {
  final TabController controller;
  final int all, active, sold;
  const _TabBar({required this.controller, required this.all, required this.active, required this.sold});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('Tất cả($all)', 0),
      ('Đang bán ($active)', 1),
      ('Đã bán($sold)', 2),
    ];
    return Row(
      children: tabs.map((t) {
        final selected = controller.index == t.$2;
        return GestureDetector(
          onTap: () => controller.animateTo(t.$2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppTheme.secondary : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              t.$1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF666666),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---- Listing card ----
class _ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ListingCard({required this.listing, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l = listing;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/listing/${l.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ảnh
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: l.thumbnailUrl.isNotEmpty
                        ? NetImage(url: l.thumbnailUrl, width: 80, height: 80)
                        : Container(
                            width: 80, height: 80,
                            color: const Color(0xFFEEEEEE),
                            child: const Icon(Icons.image, color: AppTheme.textSecondary),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(l.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(status: l.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${FormatUtils.formatPrice(l.price)} đ',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: AppTheme.textSecondary),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(l.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppTheme.textSecondary)),
                            ),
                            Text(
                              _timeAgo(l.createdAt),
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Action buttons
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ActionBtn(
                    icon: Icons.edit_outlined,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    icon: Icons.more_horiz,
                    onTap: () => _showMore(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Xem tin đăng'),
              onTap: () {
                Navigator.pop(context);
                context.push('/listing/${listing.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.error),
              title: const Text('Xóa tin', style: TextStyle(color: AppTheme.error)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inMinutes < 60) return 'Đăng ${diff.inMinutes}p trước';
    if (diff.inHours < 24) return 'Đăng ${diff.inHours}h trước';
    return 'Đăng ${diff.inDays}d trước';
  }
}

// ---- Status badge ----
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (status) {
      case 'Active':
        bg = AppTheme.secondary;
        label = 'Đang bán';
        break;
      case 'Sold':
        bg = const Color(0xFF9E9E9E);
        label = 'Đã bán';
        break;
      case 'Hidden':
        bg = const Color(0xFFFF8C00);
        label = 'Đã ẩn';
        break;
      default:
        bg = AppTheme.textSecondary;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}

// ---- Action button ----
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF555555)),
      ),
    );
  }
}
