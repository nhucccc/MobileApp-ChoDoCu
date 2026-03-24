import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget hiển thị ảnh từ URL — dùng Image.network trên web, CachedNetworkImage trên mobile
class NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  const NetImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();

    if (kIsWeb) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _shimmer(),
        errorBuilder: (_, __, ___) => errorWidget ?? _placeholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => _shimmer(),
      errorWidget: (_, __, ___) => errorWidget ?? _placeholder(),
    );
  }

  Widget _shimmer() => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.white, width: width, height: height),
      );

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: const Color(0xFFEEEEEE),
        child: const Icon(Icons.image, color: Color(0xFFAAAAAA), size: 32),
      );
}

/// ImageProvider cho CircleAvatar — dùng NetworkImage trên web
ImageProvider netImageProvider(String url) {
  if (kIsWeb) return NetworkImage(url);
  return CachedNetworkImageProvider(url);
}
