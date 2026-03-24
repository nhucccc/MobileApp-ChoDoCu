import '../../../core/network/api_client.dart';
import '../../../models/address_model.dart';

class AddressService {
  final _api = ApiClient();

  Future<List<AddressModel>> getAll() async {
    final res = await _api.dio.get('/addresses');
    return (res.data as List).map((e) => AddressModel.fromJson(e)).toList();
  }

  Future<AddressModel> create({
    required String fullName,
    required String phoneNumber,
    required String street,
    required String district,
    required String city,
    bool isDefault = false,
  }) async {
    final res = await _api.dio.post('/addresses', data: {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'street': street,
      'district': district,
      'city': city,
      'isDefault': isDefault,
    });
    return AddressModel.fromJson(res.data);
  }

  Future<AddressModel> update(int id, Map<String, dynamic> data) async {
    final res = await _api.dio.put('/addresses/$id', data: data);
    return AddressModel.fromJson(res.data);
  }

  Future<void> delete(int id) async {
    await _api.dio.delete('/addresses/$id');
  }

  Future<AddressModel> setDefault(int id) async {
    final res = await _api.dio.patch('/addresses/$id/default');
    return AddressModel.fromJson(res.data);
  }
}
