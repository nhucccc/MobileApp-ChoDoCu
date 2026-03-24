import 'package:intl/intl.dart';

class FormatUtils {
  static String formatPrice(double price) {
    final f = NumberFormat('#,###', 'vi_VN');
    return '${f.format(price)}đ';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'vi_VN').format(date.toLocal());
  }

  static String timeAgo(DateTime date) {
    // Đảm bảo so sánh UTC với UTC để tránh lệch múi giờ
    final utcDate = date.isUtc ? date : date.toUtc();
    final diff = DateTime.now().toUtc().difference(utcDate);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return formatDate(date);
  }
}
