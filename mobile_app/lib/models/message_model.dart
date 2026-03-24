import 'listing_model.dart';
import 'user_model.dart';

class MessageModel {
  final int id;
  final String content;
  final bool isRead;
  final DateTime sentAt;
  final int senderId;

  MessageModel({
    required this.id,
    required this.content,
    required this.isRead,
    required this.sentAt,
    required this.senderId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'],
        content: json['content'],
        isRead: json['isRead'] ?? false,
        sentAt: DateTime.parse(json['sentAt']).toUtc(),
        senderId: json['senderId'],
      );
}

class ConversationModel {
  final int id;
  final UserModel otherUser;
  final ListingModel listing;
  final MessageModel? lastMessage;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.otherUser,
    required this.listing,
    this.lastMessage,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) => ConversationModel(
        id: json['id'],
        otherUser: UserModel.fromJson(json['otherUser']),
        listing: _parseListingFromConv(json['listing']),
        lastMessage: json['lastMessage'] != null
            ? MessageModel.fromJson(json['lastMessage'])
            : null,
        unreadCount: json['unreadCount'] ?? 0,
      );

  static ListingModel _parseListingFromConv(Map<String, dynamic> j) {
    // Listing trong conversation không có seller — tạo dummy
    final dummySeller = UserModel(
      id: 0, fullName: '', email: '', rating: 0, ratingCount: 0,
      createdAt: DateTime.now(),
    );
    return ListingModel(
      id: j['id'],
      title: j['title'] ?? '',
      description: '',
      price: (j['price'] as num?)?.toDouble() ?? 0,
      category: '',
      condition: '',
      location: '',
      status: 'Active',
      viewCount: 0,
      createdAt: DateTime.now(),
      imageUrls: List<String>.from(j['imageUrls'] ?? []),
      seller: dummySeller,
      isFavorited: false,
    );
  }
}
