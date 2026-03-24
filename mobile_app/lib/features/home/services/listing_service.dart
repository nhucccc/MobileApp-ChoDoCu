import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../models/listing_model.dart';

class ListingService {
  final _api = ApiClient();

  Future<Map<String, dynamic>> getListings({
    String? keyword,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? condition,
    String? sortBy,
    int page = 1,
  }) async {
    final res = await _api.dio.get('/listings', queryParameters: {
      if (keyword != null) 'keyword': keyword,
      if (category != null) 'category': category,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (location != null) 'location': location,
      if (condition != null) 'condition': condition,
      if (sortBy != null) 'sortBy': sortBy,
      'page': page,
      'pageSize': 20,
    });
    return {
      'total': res.data['total'],
      'items': (res.data['items'] as List).map((e) => ListingModel.fromJson(e)).toList(),
    };
  }

  Future<ListingModel> getListing(int id) async {
    final res = await _api.dio.get('/listings/$id');
    return ListingModel.fromJson(res.data);
  }

  Future<ListingModel> createListing({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required List<String> imageUrls,
    int stock = 1,
    String? location,
    String? videoUrl,
  }) async {
    final res = await _api.dio.post('/listings', data: {
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'imageUrls': imageUrls,
      'stock': stock,
      if (location != null) 'location': location,
      if (videoUrl != null) 'videoUrl': videoUrl,
    });
    return ListingModel.fromJson(res.data);
  }

  Future<void> updateListing(int id, Map<String, dynamic> data) async {
    await _api.dio.put('/listings/$id', data: data);
  }

  Future<void> deleteListing(int id) async {
    await _api.dio.delete('/listings/$id');
  }

  Future<bool> toggleFavorite(int id) async {
    final res = await _api.dio.post('/listings/$id/favorite');
    return res.data['favorited'] as bool;
  }

  Future<List<ListingModel>> getFavorites() async {
    final res = await _api.dio.get('/listings/favorites');
    return (res.data as List).map((e) => ListingModel.fromJson(e)).toList();
  }

  Future<List<ListingModel>> getUserListings(int userId) async {
    final res = await _api.dio.get('/listings/user/$userId');
    return (res.data as List).map((e) => ListingModel.fromJson(e)).toList();
  }

  Future<String> uploadImage(String filePath) async {
    MultipartFile multipartFile;
    if (kIsWeb) {
      // Trên web: dùng XFile để đọc bytes
      final xfile = XFile(filePath);
      final bytes = await xfile.readAsBytes();
      final name = xfile.name.isNotEmpty ? xfile.name : 'image.jpg';
      multipartFile = MultipartFile.fromBytes(bytes, filename: name);
    } else {
      multipartFile = await MultipartFile.fromFile(filePath);
    }
    final formData = FormData.fromMap({'file': multipartFile});
    final res = await _api.dio.post('/upload/image', data: formData);
    return res.data['url'] as String;
  }

  Future<String> uploadImageXFile(XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    final name = xfile.name.isNotEmpty ? xfile.name : 'image.jpg';
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: name),
    });
    final res = await _api.dio.post('/upload/image', data: formData);
    return res.data['url'] as String;
  }

  Future<Map<String, String>> uploadVideo(XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    final name = xfile.name.isNotEmpty ? xfile.name : 'video.mp4';
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: name),
    });
    final res = await _api.dio.post('/upload/video', data: formData,
        options: Options(sendTimeout: const Duration(minutes: 5),
            receiveTimeout: const Duration(minutes: 5)));
    return {
      'url': res.data['url'] as String,
      'thumbnailUrl': res.data['thumbnailUrl'] as String,
    };
  }
}
