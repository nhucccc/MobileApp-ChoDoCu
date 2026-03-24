import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/file_picker_util.dart';
import '../../../core/widgets/net_image.dart';
import '../../../features/auth/services/auth_provider.dart';
import '../../../features/home/services/listing_service.dart';
import '../services/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _hasText = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      final has = _msgCtrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().openConversation(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    context.read<ChatProvider>().closeConversation();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await context.read<ChatProvider>().sendMessage(widget.conversationId, text);
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    final picked = await FilePickerUtil.pickImage();
    if (picked == null) return;

    setState(() => _uploadingImage = true);
    try {
      final xfile = XFile.fromData(picked.bytes, name: picked.name, mimeType: 'image/jpeg');
      final url = await ListingService().uploadImageXFile(xfile);
      if (!mounted) return;
      await context.read<ChatProvider>().sendMessage(widget.conversationId, '[image]$url');
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gửi ảnh: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final myId = context.read<AuthProvider>().user?.id;

    // Lấy tên người kia từ conversation hiện tại
    final conv = chat.conversations.where((c) => c.id == widget.conversationId).firstOrNull;
    final otherName = conv?.otherUser.fullName ?? 'Tin nhắn';
    final otherAvatar = conv?.otherUser.avatarUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A), size: 22),
          ),
          onPressed: () => context.pop(),
        ),
        title: GestureDetector(
          onTap: conv != null
              ? () => context.push('/partner/${conv.otherUser.id}')
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE0E0E0),
                backgroundImage: otherAvatar != null
                    ? netImageProvider(otherAvatar)
                    : null,
                child: otherAvatar == null
                    ? Text(otherName[0].toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14))
                    : null,
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A)),
                  ),
                  const Text(
                    'Xem trang cá nhân',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A1A)),
            onPressed: () {},
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: Column(
        children: [
          // ---- Messages ----
          Expanded(
            child: chat.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('Bắt đầu cuộc trò chuyện',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: chat.messages.length,
                    itemBuilder: (_, i) {
                      final msg = chat.messages[i];
                      final isMe = msg.senderId == myId;
                      final showTime = i == chat.messages.length - 1 ||
                          chat.messages[i + 1].senderId != msg.senderId;
                      return _MessageBubble(
                        content: msg.content,
                        isMe: isMe,
                        time: showTime
                            ? FormatUtils.timeAgo(msg.sentAt)
                            : null,
                        avatarUrl: !isMe ? otherAvatar : null,
                        avatarLetter: !isMe ? otherName[0] : null,
                        showAvatar: !isMe && showTime,
                      );
                    },
                  ),
          ),

          // ---- Input bar ----
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Camera icon
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: _uploadingImage ? null : _pickAndSendImage,
                      child: Container(
                        width: 36, height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F0F0),
                          shape: BoxShape.circle,
                        ),
                        child: _uploadingImage
                            ? const Padding(
                                padding: EdgeInsets.all(9),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppTheme.secondary),
                              )
                            : const Icon(Icons.photo_outlined,
                                size: 18, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // AI icon
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome_outlined,
                            size: 18, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Text input
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        maxLines: 4,
                        minLines: 1,
                        style: const TextStyle(fontSize: 14),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          hintStyle: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: _send,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: _hasText
                              ? AppTheme.secondary
                              : const Color(0xFFBBBBBB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_upward_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Message bubble ----
class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final String? time;
  final String? avatarUrl;
  final String? avatarLetter;
  final bool showAvatar;

  const _MessageBubble({
    required this.content,
    required this.isMe,
    this.time,
    this.avatarUrl,
    this.avatarLetter,
    required this.showAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar người kia
          if (!isMe) ...[
            showAvatar
                ? CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFE0E0E0),
                    backgroundImage: avatarUrl != null
                        ? netImageProvider(avatarUrl!)
                        : null,
                    child: avatarUrl == null
                        ? Text(avatarLetter ?? '?',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700))
                        : null,
                  )
                : const SizedBox(width: 28),
            const SizedBox(width: 6),
          ],

          // Bubble
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65),
                decoration: BoxDecoration(
                  color: content.startsWith('[image]')
                      ? Colors.transparent
                      : (isMe ? AppTheme.secondary : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: content.startsWith('[image]')
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: content.startsWith('[image]')
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isMe ? 18 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 18),
                        ),
                        child: _ChatImage(url: content.substring(7)),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Text(
                          content,
                          style: TextStyle(
                            fontSize: 14,
                            color: isMe ? Colors.white : const Color(0xFF1A1A1A),
                            height: 1.4,
                          ),
                        ),
                      ),
              ),
              if (time != null) ...[
                const SizedBox(height: 3),
                Text(
                  time!,
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Chat image — dùng NetImage (hoạt động cả web lẫn mobile) ----
class _ChatImage extends StatelessWidget {
  final String url;
  const _ChatImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: NetImage(
        url: url,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorWidget: Container(
          width: 200, height: 200,
          color: const Color(0xFFEEEEEE),
          child: const Icon(Icons.broken_image_outlined, color: Color(0xFFAAAAAA), size: 40),
        ),
      ),
    );
  }
}
