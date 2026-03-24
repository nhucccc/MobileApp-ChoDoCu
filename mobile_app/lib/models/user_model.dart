class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;
  final double rating;
  final int ratingCount;
  final DateTime createdAt;
  final String? gender;
  final DateTime? birthday;
  final bool isVerified;
  final String role;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    required this.rating,
    required this.ratingCount,
    required this.createdAt,
    this.gender,
    this.birthday,
    this.isVerified = false,
    this.role = 'User',
  });

  bool get isAdmin => role == 'Admin';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        fullName: json['fullName'],
        email: json['email'],
        phoneNumber: json['phoneNumber'],
        avatarUrl: json['avatarUrl'],
        bio: json['bio'],
        rating: (json['rating'] as num).toDouble(),
        ratingCount: json['ratingCount'],
        createdAt: DateTime.parse(json['createdAt']).toUtc(),
        gender: json['gender'],
        birthday: json['birthday'] != null ? DateTime.parse(json['birthday']).toUtc() : null,
        isVerified: json['isVerified'] ?? false,
        role: json['role'] ?? 'User',
      );
}
