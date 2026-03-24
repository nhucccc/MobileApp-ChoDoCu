import '../../../core/network/api_client.dart';

class AdminService {
  final _api = ApiClient();

  Future<Map<String, dynamic>> getStats() async {
    final res = await _api.dio.get('/admin/stats');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUsers({String? keyword, int page = 1}) async {
    final res = await _api.dio.get('/admin/users', queryParameters: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      'page': page,
      'pageSize': 20,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> setUserRole(int id, String role) async {
    await _api.dio.put('/admin/users/$id/role', data: {'role': role});
  }

  Future<void> deleteUser(int id) async {
    await _api.dio.delete('/admin/users/$id');
  }

  Future<Map<String, dynamic>> getListings({String? keyword, String? status, int page = 1}) async {
    final res = await _api.dio.get('/admin/listings', queryParameters: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (status != null) 'status': status,
      'page': page,
      'pageSize': 20,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteListing(int id) async {
    await _api.dio.delete('/admin/listings/$id');
  }

  Future<void> setListingStatus(int id, String status) async {
    await _api.dio.put('/admin/listings/$id/status', data: {'status': status});
  }

  Future<Map<String, dynamic>> getOrders({String? status, int page = 1}) async {
    final res = await _api.dio.get('/admin/orders', queryParameters: {
      if (status != null) 'status': status,
      'page': page,
      'pageSize': 20,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> setOrderStatus(int id, String status) async {
    await _api.dio.put('/admin/orders/$id/status', data: {'status': status});
  }

  Future<Map<String, dynamic>> getWithdrawals({String? status, int page = 1}) async {
    final res = await _api.dio.get('/admin/withdrawals', queryParameters: {
      if (status != null) 'status': status,
      'page': page,
      'pageSize': 20,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> approveWithdrawal(int id) async {
    await _api.dio.patch('/admin/withdrawals/$id/approve');
  }

  Future<void> rejectWithdrawal(int id, String reason) async {
    await _api.dio.patch('/admin/withdrawals/$id/reject', data: {'reason': reason});
  }

  Future<String> broadcastNotification({
    required String title,
    required String body,
    String type = 'Promotion',
    String targetRole = 'User',
    String? actionUrl,
  }) async {
    final res = await _api.dio.post('/admin/notifications/broadcast', data: {
      'title': title,
      'body': body,
      'type': type,
      'targetRole': targetRole,
      if (actionUrl != null) 'actionUrl': actionUrl,
    });
    return (res.data as Map<String, dynamic>)['message'] as String;
  }
}
