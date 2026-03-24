import 'user_model.dart';

class ReviewModel {
  final int id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final UserModel reviewer;

  ReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.reviewer,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'],
        rating: json['rating'],
        comment: json['comment'],
        createdAt: DateTime.parse(json['createdAt']).toUtc(),
        reviewer: UserModel.fromJson(json['reviewer']),
      );
}
