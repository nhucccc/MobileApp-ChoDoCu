import 'user_model.dart';

class ListingModel {
  final int id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final String location;
  final String status;
  final int stock;
  final int viewCount;
  final DateTime createdAt;
  final List<String> imageUrls;
  final String? videoUrl;
  final UserModel seller;
  bool isFavorited;

  ListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.location,
    required this.status,
    this.stock = 1,
    required this.viewCount,
    required this.createdAt,
    required this.imageUrls,
    this.videoUrl,
    required this.seller,
    required this.isFavorited,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) => ListingModel(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        price: (json['price'] as num).toDouble(),
        category: json['category'],
        condition: json['condition'] ?? '',
        location: json['location'] ?? '',
        status: json['status'],
        stock: json['stock'] ?? 1,
        viewCount: json['viewCount'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']).toUtc(),
        imageUrls: List<String>.from(json['imageUrls'] ?? []),
        videoUrl: json['videoUrl'] as String?,
        seller: UserModel.fromJson(json['seller']),
        isFavorited: json['isFavorited'] ?? false,
      );

  String get thumbnailUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  int get imageCount => imageUrls.length;
}
