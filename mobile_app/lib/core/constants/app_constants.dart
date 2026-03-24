class AppConstants {
  static const String _host = 'berlinmmo.site';

  static String get baseUrl => 'https://$_host/api';
  static String get hubUrl => 'https://$_host/hubs/chat';

  static const List<String> categories = [
    'Thời trang nam',
    'Thời trang nữ',
    'Sách',
    'Đồ chơi',
    'Đồ thể thao',
    'Đồ gia dụng',
    'Điện thoại & máy tính',
    'Xe cộ',
    'Đồ điện gia dụng',
    'Mỹ phẩm',
    'Nhà cửa',
    'Khác',
  ];
}
