import '../../../core/network/api_client.dart';
import '../../../models/order_model.dart';

class OrderService {
  final _api = ApiClient();

  Future<List<OrderModel>> getPurchases({String? status}) async {
    final res = await _api.dio.get('/orders/purchases', queryParameters: {
      if (status != null && status != 'all') 'status': status,
    });
    return (res.data as List).map((e) => OrderModel.fromJson(e)).toList();
  }

  Future<List<OrderModel>> getSales({String? status}) async {
    final res = await _api.dio.get('/orders/sales', queryParameters: {
      if (status != null && status != 'all') 'status': status,
    });
    return (res.data as List).map((e) => OrderModel.fromJson(e)).toList();
  }

  Future<OrderModel> createOrder(int listingId, {int quantity = 1}) async {
    final res = await _api.dio.post('/orders', data: {
      'listingId': listingId,
      'quantity': quantity,
    });
    return OrderModel.fromJson(res.data);
  }

  Future<void> cancelOrder(int id) async {
    await _api.dio.patch('/orders/$id/cancel');
  }

  Future<void> updateStatus(int id, String status) async {
    await _api.dio.patch('/orders/$id/status', data: {'status': status});
  }

  Future<void> confirmReceived(int id) async {
    await _api.dio.patch('/orders/$id/confirm-received');
  }
}
