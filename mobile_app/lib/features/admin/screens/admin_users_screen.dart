import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _svc = AdminService();
  final _searchCtrl = TextEditingController();
  List<dynamic> _users = [];
  int _total = 0, _page = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) _page = 1;
    setState(() => _loading = true);
    try {
      final res = await _svc.getUsers(keyword: _searchCtrl.text, page: _page);
      setState(() {
        if (reset || _page == 1) {
          _users = res['items'] as List;
        } else {
          _users = [..._users, ...(res['items'] as List)];
        }
        _total = res['total'] as int;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setRole(int id, bool isAdmin) async {
    final newRole = isAdmin ? 'User' : 'Admin';
    final ok = await _confirm('Đổi quyền', 'Đổi thành $newRole?');
    if (ok) { await _svc.setUserRole(id, newRole); _load(reset: true); }
  }

  Future<void> _delete(int id, String name) async {
    final ok = await _confirm('Xóa người dùng', 'Xóa "$name"? Không thể hoàn tác.', danger: true);
    if (ok) { await _svc.deleteUser(id); _load(reset: true); }
  }

  Future<bool> _confirm(String title, String msg, {bool danger = false}) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text(title),
            content: Text(msg),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Xác nhận',
                    style: TextStyle(color: danger ? AppTheme.error : AppTheme.primary)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildSearch(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              Text('$_total người dùng', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ]),
          ),
          Expanded(
            child: _loading && _users.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : RefreshIndicator(
                    onRefresh: () => _load(reset: true),
                    color: AppTheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: _users.length + (_users.length < _total ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _users.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: TextButton(
                              onPressed: () { _page++; _load(); },
                              child: const Text('Tải thêm'),
                            ),
                          );
                        }
                        return _UserCard(
                          user: _users[i],
                          onSetRole: _setRole,
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

  Widget _buildSearch() => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, email...',
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
            _iconBtn(Icons.search, AppTheme.primary, () => _load(reset: true)),
          ],
        ),
      );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}

class _UserCard extends StatelessWidget {
  final dynamic user;
  final void Function(int, bool) onSetRole;
  final void Function(int, String) onDelete;
  const _UserCard({required this.user, required this.onSetRole, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final u = user as Map<String, dynamic>;
    final roleVal = u['role'];
    final isAdmin = roleVal == 1 || roleVal == 'Admin' || roleVal.toString() == '1';
    final name = u['fullName'] as String? ?? '';
    final email = u['email'] as String? ?? '';
    final wallet = (u['walletBalance'] as num?)?.toDouble() ?? 0;
    final listings = u['listingCount'] as int? ?? 0;
    final verified = u['isVerified'] as bool? ?? false;

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
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isAdmin
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : const Color(0xFF5C6BC0).withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isAdmin ? AppTheme.primary : const Color(0xFF5C6BC0)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (isAdmin)
                        _badge('Admin', AppTheme.primary),
                      if (verified)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: _badge('Đã xác minh', AppTheme.secondary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(email,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _infoChip(Icons.inventory_2_outlined, '$listings tin'),
                      const SizedBox(width: 8),
                      _infoChip(Icons.account_balance_wallet_outlined, _fmt(wallet)),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (v) {
                if (v == 'role') onSetRole(u['id'], isAdmin);
                if (v == 'delete') onDelete(u['id'], name);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'role',
                  child: Row(children: [
                    Icon(isAdmin ? Icons.person_outline : Icons.admin_panel_settings_outlined,
                        size: 18, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(isAdmin ? 'Hạ xuống User' : 'Nâng lên Admin'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                    const SizedBox(width: 8),
                    const Text('Xóa', style: TextStyle(color: AppTheme.error)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      );

  Widget _infoChip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      );

  String _fmt(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}Mđ';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}Kđ';
    return '${n.toStringAsFixed(0)}đ';
  }
}
