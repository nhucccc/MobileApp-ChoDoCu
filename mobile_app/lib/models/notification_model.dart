class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? actionUrl;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.actionUrl,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        type: json['type'],
        isRead: json['isRead'],
        actionUrl: json['actionUrl'],
        createdAt: DateTime.parse(json['createdAt']).toUtc(),
      );
}
