import '../../core/network/api_client.dart';
import '../../models/notification_model.dart';

class NotificationService {
  final _api = ApiClient();

  Future<Map<String, dynamic>> getAll({int page = 1}) async {
    final res = await _api.dio.get('/notifications', queryParameters: {'page': page});
    return {
      'total': res.data['total'],
      'unreadCount': res.data['unreadCount'],
      'items': (res.data['items'] as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList(),
    };
  }

  Future<void> markRead(int id) async {
    await _api.dio.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.dio.patch('/notifications/read-all');
  }

  Future<void> delete(int id) async {
    await _api.dio.delete('/notifications/$id');
  }
}
