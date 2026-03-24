import 'package:signalr_netcore/signalr_client.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/message_model.dart';

class ChatService {
  final _api = ApiClient();
  HubConnection? _hubConnection;

  bool get isDisconnected =>
      _hubConnection == null ||
      _hubConnection!.state == HubConnectionState.Disconnected;

  Future<List<ConversationModel>> getConversations() async {
    final res = await _api.dio.get('/chat/conversations');
    return (res.data as List).map((e) => ConversationModel.fromJson(e)).toList();
  }

  Future<List<MessageModel>> getMessages(int conversationId, {int page = 1}) async {
    final res = await _api.dio.get(
      '/chat/conversations/$conversationId/messages',
      queryParameters: {'page': page},
    );
    return (res.data as List).map((e) => MessageModel.fromJson(e)).toList();
  }

  Future<int> startConversation({
    required int sellerId,
    required int listingId,
    required String firstMessage,
  }) async {
    final res = await _api.dio.post('/chat/start', data: {
      'sellerId': sellerId,
      'listingId': listingId,
      'firstMessage': firstMessage,
    });
    return res.data['conversationId'] as int;
  }

  Future<void> connectHub(Function(Map<String, dynamic>) onMessage) async {
    final token = await _api.getToken();
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          AppConstants.hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token ?? '',
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hubConnection!.on('ReceiveMessage', (args) {
      if (args != null && args.isNotEmpty) {
        onMessage(Map<String, dynamic>.from(args[0] as Map));
      }
    });

    await _hubConnection!.start();
  }

  Future<void> sendMessage(int conversationId, String content) async {
    await _hubConnection?.invoke('SendMessage', args: [conversationId, content]);
  }

  Future<void> markAsRead(int conversationId) async {
    await _hubConnection?.invoke('MarkAsRead', args: [conversationId]);
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
    _hubConnection = null;
  }
}
