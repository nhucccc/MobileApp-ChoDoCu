class OrderModel {
  final int id;
  final String status;
  final double totalAmount;
  final int quantity;
  final DateTime createdAt;
  final OrderListingModel listing;
  final OrderSellerModel seller;
  final OrderSellerModel? buyer;
  // Thông tin thêm khi navigate từ checkout
  final String? shippingAddress;
  final String? payMethod;

  OrderModel({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.quantity,
    required this.createdAt,
    required this.listing,
    required this.seller,
    this.buyer,
    this.shippingAddress,
    this.payMethod,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'],
        status: json['status'],
        totalAmount: (json['totalAmount'] as num).toDouble(),
        quantity: json['quantity'],
        createdAt: DateTime.parse(json['createdAt']).toUtc(),
        listing: OrderListingModel.fromJson(json['listing']),
        seller: OrderSellerModel.fromJson(json['seller']),
        buyer: json['buyer'] != null ? OrderSellerModel.fromJson(json['buyer']) : null,
      );

  String get statusLabel {
    switch (status) {
      case 'Pending': return 'Chờ xác nhận';
      case 'Processing': return 'Đang xử lý';
      case 'Shipping': return 'Chờ giao hàng';
      case 'Delivered': return 'Đơn hàng đã được giao';
      case 'Returned': return 'Trả hàng';
      case 'Cancelled': return 'Đơn hàng đã bị hủy';
      default: return status;
    }
  }

  bool get canCancel => status == 'Pending';
}

class OrderListingModel {
  final int id;
  final String title;
  final String thumbnailUrl;
  final double price;

  OrderListingModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.price,
  });

  factory OrderListingModel.fromJson(Map<String, dynamic> json) =>
      OrderListingModel(
        id: json['id'],
        title: json['title'],
        thumbnailUrl: json['thumbnailUrl'] ?? '',
        price: (json['price'] as num).toDouble(),
      );
}

class OrderSellerModel {
  final int id;
  final String fullName;
  final String? avatarUrl;

  OrderSellerModel({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  factory OrderSellerModel.fromJson(Map<String, dynamic> json) =>
      OrderSellerModel(
        id: json['id'],
        fullName: json['fullName'],
        avatarUrl: json['avatarUrl'],
      );
}
