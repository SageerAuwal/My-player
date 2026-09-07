import 'package:flutter/material.dart';
import '../../../../core/models/media_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/spatial_card.dart';

class MediaCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const MediaCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SpatialCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Media Thumbnail / Icon Placeholder
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  item.isVideo ? Icons.movie_outlined : Icons.music_note_outlined,
                  color: AppColors.primary.withOpacity(0.7),
                  size: 32,
                ),
                if (item.isVideo && item.durationMs > 0)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.formattedDuration,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Media Metadata & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item.artist != null && item.artist!.isNotEmpty) ...[
                      Text(
                        item.artist!,
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                    Text(
                      item.formattedSize,
                      style: AppTypography.bodySmall,
                    ),
                    if (item.isAudio && item.durationMs > 0) ...[
                      const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                      Text(
                        item.formattedDuration,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ],
                ),
                if (item.lastPositionMs > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: item.progressPercentage,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 3,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Favorite Button
          IconButton(
            icon: Icon(
              item.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: item.isFavorite ? AppColors.error : AppColors.textSecondary,
              size: 22,
            ),
            onPressed: onFavoriteToggle,
          ),
        ],
      ),
    ),
    );
  }
}
