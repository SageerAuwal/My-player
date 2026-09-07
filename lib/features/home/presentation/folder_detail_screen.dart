import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/media_folder.dart';
import '../../../core/models/media_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../video/presentation/video_player_screen.dart';
import '../controller/media_providers.dart';
import 'widgets/media_card.dart';

class FolderDetailScreen extends ConsumerStatefulWidget {
  final MediaFolder folder;

  const FolderDetailScreen({
    super.key,
    required this.folder,
  });

  @override
  ConsumerState<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends ConsumerState<FolderDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.folder.items.where((item) {
      if (_filterQuery.isEmpty) return true;
      return item.title.toLowerCase().contains(_filterQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceGlass,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.folder.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.folder.items.length} videos • ${widget.folder.formattedSize}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          if (filteredItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton.icon(
                onPressed: () => _playAll(filteredItems),
                icon: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 20),
                label: const Text(
                  'Play All',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GlassPanel(
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _filterQuery = val;
                  });
                },
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search in ${widget.folder.name}...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _filterQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
      body: filteredItems.isEmpty
          ? Center(
              child: Text(
                _filterQuery.isEmpty ? 'No videos in this folder' : 'No matching videos found',
                style: AppTypography.titleMedium,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return MediaCard(
                  item: item,
                  onTap: () => _openVideo(item),
                  onFavoriteToggle: () {
                    if (item.id != null) {
                      ref.read(mediaNotifierProvider.notifier).toggleFavorite(item.id!);
                    }
                  },
                );
              },
            ),
    );
  }

  void _openVideo(MediaItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          mediaItem: item,
          playlist: widget.folder.items,
        ),
      ),
    );
  }

  void _playAll(List<MediaItem> items) {
    if (items.isNotEmpty) {
      _openVideo(items.first);
    }
  }
}
