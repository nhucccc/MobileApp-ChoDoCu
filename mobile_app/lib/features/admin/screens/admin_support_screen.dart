import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/net_image.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final _api = ApiClient();
  List<_SupportUser> _users = [];
  bool _loading = true;
  _SupportUser? _selected;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadUsers(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUsers({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final res = await _api.dio.get('/support/admin/users');
      final list = (res.data as List)
          .map((e) => _SupportUser.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _users = list);
    } catch (_) {}
    if (!silent && mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    if (isWide) {
      return Row(
        children: [
          SizedBox(width: 300, child: _UserList(users: _users, loading: _loading, selected: _selected, onSelect: (u) => setState(() => _selected = u))),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selected == null
                ? const Center(child: Text('Chọn một cuộc trò chuyện', style: TextStyle(color: AppTheme.textSecondary)))
                : _ChatPanel(user: _selected!, key: ValueKey(_selected!.userId)),
          ),
        ],
      );
    }

    return _selected == null
        ? _UserList(users: _users, loading: _loading, selected: null, onSelect: (u) => setState(() => _selected = u))
        : WillPopScope(
            onWillPop: () async { setState(() => _selected = null); return false; },
            child: _ChatPanel(user: _selected!, key: ValueKey(_selected!.userId)),
          );
  }
}

class _SupportUser {
  final int userId;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime lastAt;
  final int unreadCount;

  _SupportUser({
    required this.userId, required this.fullName, required this.email,
    this.avatarUrl, required this.lastMessage, required this.lastAt, required this.unreadCount,
  });

  factory _SupportUser.fromJson(Map<String, dynamic> j) => _SupportUser(
    userId: j['userId'],
    fullName: j['fullName'],
    email: j['email'],
    avatarUrl: j['avatarUrl'],
    lastMessage: j['lastMessage'],
    lastAt: DateTime.parse(j['lastAt']).toLocal(),
    unreadCount: j['unreadCount'],
  );
}

class _UserList extends StatelessWidget {
  final List<_SupportUser> users;
  final bool loading;
  final _SupportUser? selected;
  final void Function(_SupportUser) onSelect;
  const _UserList({required this.users, required this.loading, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Tin nhắn hỗ trợ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const Divider(height: 1),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
                : users.isEmpty
                    ? const Center(child: Text('Chưa có tin nhắn nào', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)))
                    : ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                        itemBuilder: (_, i) {
                          final u = users[i];
                          final isSelected = selected?.userId == u.userId;
                          return InkWell(
                            onTap: () => onSelect(u),
                            child: Container(
                              color: isSelected ? AppTheme.secondary.withValues(alpha: 0.08) : null,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFFE0E0E0),
                                    backgroundImage: u.avatarUrl != null ? netImageProvider(u.avatarUrl!) : null,
                                    child: u.avatarUrl == null
                                        ? Text(u.fullName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700))
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: Text(u.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                                            Text(FormatUtils.timeAgo(u.lastAt), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(u.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 12, color: u.unreadCount > 0 ? const Color(0xFF1A1A1A) : AppTheme.textSecondary,
                                                      fontWeight: u.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal)),
                                            ),
                                            if (u.unreadCount > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: AppTheme.secondary, borderRadius: BorderRadius.circular(10)),
                                                child: Text('${u.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ChatPanel extends StatefulWidget {
  final _SupportUser user;
  const _ChatPanel({required this.user, super.key});

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final _api = ApiClient();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<_SupportMsg> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final res = await _api.dio.get('/support/admin/messages/${widget.user.userId}');
      final list = (res.data as List).map((e) => _SupportMsg.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) setState(() => _messages = list);
    } catch (_) {}
    if (!silent && mounted) setState(() => _loading = false);
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      final res = await _api.dio.post('/support/admin/reply/${widget.user.userId}', data: {'content': text});
      final msg = _SupportMsg.fromJson(res.data as Map<String, dynamic>);
      if (mounted) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE0E0E0),
                backgroundImage: widget.user.avatarUrl != null ? netImageProvider(widget.user.avatarUrl!) : null,
                child: widget.user.avatarUrl == null
                    ? Text(widget.user.fullName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.user.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(widget.user.email, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Messages
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
              : _messages.isEmpty
                  ? const Center(child: Text('Chưa có tin nhắn', style: TextStyle(color: AppTheme.textSecondary)))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];
                        final isAdmin = msg.isFromAdmin;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              if (!isAdmin) ...[
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  backgroundImage: widget.user.avatarUrl != null ? netImageProvider(widget.user.avatarUrl!) : null,
                                  child: widget.user.avatarUrl == null
                                      ? Text(widget.user.fullName[0].toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))
                                      : null,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Column(
                                crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.55),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isAdmin ? const Color(0xFFFF8C00) : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(isAdmin ? 16 : 4),
                                        bottomRight: Radius.circular(isAdmin ? 4 : 16),
                                      ),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))],
                                    ),
                                    child: Text(msg.content,
                                        style: TextStyle(fontSize: 13, color: isAdmin ? Colors.white : const Color(0xFF1A1A1A), height: 1.4)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(FormatUtils.timeAgo(msg.sentAt), style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
        // Input
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(22)),
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: 3, minLines: 1,
                    style: const TextStyle(fontSize: 14),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Nhập phản hồi...',
                      hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(color: Color(0xFFFF8C00), shape: BoxShape.circle),
                  child: _sending
                      ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportMsg {
  final int id;
  final String content;
  final bool isFromAdmin;
  final DateTime sentAt;

  _SupportMsg({required this.id, required this.content, required this.isFromAdmin, required this.sentAt});

  factory _SupportMsg.fromJson(Map<String, dynamic> j) => _SupportMsg(
    id: j['id'], content: j['content'], isFromAdmin: j['isFromAdmin'],
    sentAt: DateTime.parse(j['sentAt']).toLocal(),
  );
}
