import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/admin_service.dart';

class AdminListingsScreen extends StatefulWidget {
  const AdminListingsScreen({super.key});
  @override
  State<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends State<AdminListingsScreen> {
  final _svc = AdminService();
  final _searchCtrl = TextEditingController();
  List<dynamic> _items = [];
  int _total = 0, _page = 1;
  bool _loading = true;
  String? _statusFilter;

  // Trạng thái khớp với backend ListingStatus enum
  static const _statuses = [
    ('Active', 'Đang bán', AppTheme.secondary),
    ('Hidden', 'Ẩn', AppTheme.textSecondary),
    ('Sold', 'Đã bán', AppTheme.primary),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) _page = 1;
    setState(() => _loading = true);
    try {
      final res = await _svc.getListings(
          keyword: _searchCtrl.text, status: _statusFilter, page: _page);
      setState(() {
        if (reset || _page == 1) {
          _items = res['items'] as List;
        } else {
          _items = [..._items, ...(res['items'] as List)];
        }
        _total = res['total'] as int;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(int id, String current) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Đổi trạng thái tin đăng'),
        children: _statuses.map((s) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, s.$1),
          child: Row(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(s.$2,
                style: TextStyle(
                    fontWeight: s.$1 == current ? FontWeight.w700 : FontWeight.normal,
                    color: s.$1 == current ? AppTheme.primary : null)),
          ]),
        )).toList(),
      ),
    );
    if (selected != null && selected != current) {
      await _svc.setListingStatus(id, selected);
      _load(reset: true);
    }
  }

  Future<void> _delete(int id, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xóa tin đăng'),
        content: Text('Xóa "$title"? Không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (ok == true) { await _svc.deleteListing(id); _load(reset: true); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildToolbar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              Text('$_total tin đăng', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ]),
          ),
          Expanded(
            child: _loading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : RefreshIndicator(
                    onRefresh: () => _load(reset: true),
                    color: AppTheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: _items.length + (_items.length < _total ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _items.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: TextButton(
                                onPressed: () { _page++; _load(); },
                                child: const Text('Tải thêm')),
                          );
                        }
                        return _ListingCard(
                          item: _items[i],
                          onSetStatus: _setStatus,
                          onDelete: _delete,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Tìm tin đăng...',
                  hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _load(reset: true),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String?>(
              tooltip: 'Lọc trạng thái',
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              icon: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _statusFilter != null ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.filter_list,
                    color: _statusFilter != null ? Colors.white : AppTheme.textSecondary, size: 20),
              ),
              onSelected: (v) { setState(() => _statusFilter = v); _load(reset: true); },
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('Tất cả')),
                ..._statuses.map((s) => PopupMenuItem(
                      value: s.$1,
                      child: Row(children: [
                        Container(width: 8, height: 8,
                            decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(s.$2),
                      ]),
                    )),
              ],
            ),
          ],
        ),
      );
}

class _ListingCard extends StatelessWidget {
  final dynamic item;
  final void Function(int, String) onSetStatus;
  final void Function(int, String) onDelete;
  const _ListingCard({required this.item, required this.onSetStatus, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final m = item as Map<String, dynamic>;
    final status = m['status'].toString();
    final price = (m['price'] as num).toDouble();
    final stock = m['stock'] as int? ?? 0;
    final seller = m['seller'] as Map<String, dynamic>;

    Color sColor;
    String sLabel;
    switch (status) {
      case 'Active': sColor = AppTheme.secondary; sLabel = 'Đang bán'; break;
      case 'Hidden': sColor = AppTheme.textSecondary; sLabel = 'Ẩn'; break;
      case 'Sold': sColor = AppTheme.primary; sLabel = 'Đã bán'; break;
      default: sColor = AppTheme.textSecondary; sLabel = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60, height: 60,
                child: m['thumbnail'] != null
                    ? Image.network(m['thumbnail'], fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['title'] ?? '',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(_fmtPrice(price),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    const SizedBox(width: 8),
                    Text('Còn $stock', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.person_outline, size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(seller['fullName'] ?? '',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => onSetStatus(m['id'], status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: sColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(sLabel,
                        style: TextStyle(fontSize: 11, color: sColor, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => onDelete(m['id'], m['title'] ?? ''),
                  child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
      color: const Color(0xFFEEEEEE),
      child: const Icon(Icons.image, color: AppTheme.textSecondary));

  String _fmtPrice(double p) {
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}M đ';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)}K đ';
    return '${p.toStringAsFixed(0)}đ';
  }
}
