import 'package:flutter/material.dart';
import '../../../models/message_model.dart';
import 'chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final _service = ChatService();

  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  bool _loading = false;
  String? _error;
  int? _activeConversationId;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  bool get loading => _loading;
  String? get error => _error;

  int get totalUnread => _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  Future<void> connect() async {
    await _service.connectHub((data) {
      final msg = MessageModel(
        id: data['id'],
        content: data['content'],
        sentAt: DateTime.parse(data['sentAt']).toUtc(),
        senderId: data['senderId'],
        isRead: false,
      );
      final convId = data['conversationId'] as int;

      if (_activeConversationId == convId) {
        _messages.insert(0, msg);
      }

      // Cập nhật lastMessage trong danh sách conversations
      final idx = _conversations.indexWhere((c) => c.id == convId);
      if (idx != -1) {
        _conversations[idx] = ConversationModel(
          id: _conversations[idx].id,
          otherUser: _conversations[idx].otherUser,
          listing: _conversations[idx].listing,
          lastMessage: msg,
          unreadCount: _activeConversationId == convId
              ? 0
              : _conversations[idx].unreadCount + 1,
        );
      }
      notifyListeners();
    });
  }

  Future<void> loadConversations() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _conversations = await _service.getConversations();
    } catch (e) {
      _error = e.toString();
      debugPrint('loadConversations error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> openConversation(int conversationId) async {
    _activeConversationId = conversationId;
    _messages = [];
    notifyListeners();
    _messages = await _service.getMessages(conversationId);
    await _service.markAsRead(conversationId);
    notifyListeners();
  }

  Future<void> sendMessage(int conversationId, String content) async {
    await _service.sendMessage(conversationId, content);
  }

  Future<int> startConversation({
    required int sellerId,
    required int listingId,
    required String firstMessage,
  }) async {
    // Connect hub nếu chưa (không block nếu fail)
    if (_service.isDisconnected) {
      try { await connect(); } catch (_) {}
    }
    final convId = await _service.startConversation(
      sellerId: sellerId, listingId: listingId, firstMessage: firstMessage);
    // Reload ngay để conversation mới xuất hiện trong danh sách
    await loadConversations();
    return convId;
  }

  void closeConversation() {
    _activeConversationId = null;
    _messages = [];
    // Reload conversations để cập nhật unread count và lastMessage
    loadConversations();
  }

  @override
  void dispose() {
    _service.disconnect();
    super.dispose();
  }
}
