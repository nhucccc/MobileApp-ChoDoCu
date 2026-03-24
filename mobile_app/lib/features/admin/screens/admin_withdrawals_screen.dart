import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';

class AdminWithdrawalsScreen extends StatefulWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  State<AdminWithdrawalsScreen> createState() => _AdminWithdrawalsScreenState();
}

class _AdminWithdrawalsScreenState extends State<AdminWithdrawalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _api = ApiClient();

  final _tabs = const [
    ('Pending', 'Chờ duyệt'),
    ('Completed', 'Đã duyệt'),
    ('Rejected', 'Từ chối'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Quản lý rút tiền',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _tabs.map((t) => _WithdrawalList(status: t.$1, api: _api)).toList(),
      ),
    );
  }
}

class _WithdrawalList extends StatefulWidget {
  final String status;
  final ApiClient api;
  const _WithdrawalList({required this.status, required this.api});

  @override
  State<_WithdrawalList> createState() => _WithdrawalListState();
}

class _WithdrawalListState extends State<_WithdrawalList>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => false; // reload khi quay lại tab

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.api.dio.get('/admin/withdrawals',
          queryParameters: {'status': widget.status, 'pageSize': 50});
      setState(() => _items = res.data['items'] as List);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Duyệt rút tiền'),
        content: const Text('Xác nhận đã chuyển tiền cho người dùng?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Duyệt', style: TextStyle(color: AppTheme.secondary))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.api.dio.patch('/admin/withdrawals/$id/approve');
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã duyệt'), backgroundColor: AppTheme.success));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi khi duyệt')));
      }
    }
  }

  Future<void> _reject(int id) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Từ chối rút tiền'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tiền sẽ được hoàn về ví người dùng.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'Lý do từ chối (tuỳ chọn)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Từ chối', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.api.dio.patch('/admin/withdrawals/$id/reject',
          data: {'reason': reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim()});
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã từ chối và hoàn tiền'), backgroundColor: Colors.orange));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi khi từ chối')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_items.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Không có yêu cầu nào', style: TextStyle(color: AppTheme.textSecondary)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _WithdrawalCard(
          item: _items[i],
          onApprove: widget.status == 'Pending' ? () => _approve(_items[i]['id']) : null,
          onReject: widget.status == 'Pending' ? () => _reject(_items[i]['id']) : null,
        ),
      ),
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  const _WithdrawalCard({required this.item, this.onApprove, this.onReject});

  @override
  Widget build(BuildContext context) {
    final user = item['user'];
    final status = item['status'].toString();
    final amount = (item['amount'] as num).toDouble();
    final note = item['note'] as String? ?? '';
    final createdAt = DateTime.parse(item['createdAt']).toLocal();
    final dateStr =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} '
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'Pending':
        statusColor = Colors.orange;
        statusLabel = 'Chờ duyệt';
        break;
      case 'Completed':
        statusColor = AppTheme.secondary;
        statusLabel = 'Đã duyệt';
        break;
      case 'Rejected':
        statusColor = AppTheme.error;
        statusLabel = 'Từ chối';
        break;
      default:
        statusColor = AppTheme.textSecondary;
        statusLabel = status;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Text(
                  (user['fullName'] as String)[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['fullName'],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(user['email'],
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Số tiền:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              Text(
                FormatUtils.formatPrice(amount),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Số dư hiện tại:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text(
                FormatUtils.formatPrice((user['walletBalance'] as num).toDouble()),
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(note, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
          const SizedBox(height: 6),
          Text(dateStr, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          if (onApprove != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Duyệt'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
