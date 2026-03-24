import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/net_image.dart';
import '../../../models/listing_model.dart';
import '../services/listing_provider.dart';

class ListingCard extends StatelessWidget {
  final ListingModel listing;
  const ListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/listing/${listing.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Ảnh + overlay ----
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Ảnh
                    listing.thumbnailUrl.isNotEmpty
                        ? NetImage(
                            url: listing.thumbnailUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: const Color(0xFFEEEEEE),
                            child: const Icon(Icons.image, color: AppTheme.textSecondary, size: 40),
                          ),
                    // Gradient overlay dưới
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // Thời gian (dưới trái)
                    Positioned(
                      bottom: 6, left: 8,
                      child: Text(
                        FormatUtils.timeAgo(listing.createdAt),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ),
                    // Số ảnh (dưới phải)
                    Positioned(
                      bottom: 5, right: 8,
                      child: Row(
                        children: [
                          const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '${listing.imageCount > 0 ? listing.imageCount : 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    // Nút yêu thích (trên phải)
                    Positioned(
                      top: 6, right: 6,
                      child: GestureDetector(
                        onTap: () => context.read<ListingProvider>().toggleFavorite(listing.id),
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            listing.isFavorited ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: listing.isFavorited ? AppTheme.error : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ---- Info ----
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A), height: 1.3),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    FormatUtils.formatPrice(listing.price),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          listing.location.isNotEmpty ? listing.location : 'Việt Nam',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
