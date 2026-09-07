import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/media_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/glowing_button.dart';
import '../../music/presentation/music_player_screen.dart';
import '../../video/controller/playback_controller.dart';
import '../../video/presentation/video_player_screen.dart';
import '../controller/media_providers.dart';
import 'widgets/media_card.dart';

import '../../../core/models/media_folder.dart';
import 'widgets/folder_card.dart';
import 'folder_detail_screen.dart';

// ignore_for_file: unnecessary_import

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanProgress = ref.watch(scanProgressProvider);
    final videoFoldersAsync = ref.watch(videoFoldersProvider);
    final videoListAsync = ref.watch(videoListProvider);
    final audioListAsync = ref.watch(audioListProvider);
    final recentListAsync = ref.watch(recentMediaProvider);
    final favoriteListAsync = ref.watch(favoriteMediaProvider);
    final viewMode = ref.watch(videoViewModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Aura',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    shadows: [
                      Shadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Player',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              scanProgress.isScanning ? Icons.sync : Icons.refresh,
              color: AppColors.primary,
            ),
            tooltip: 'Scan Storage',
            onPressed: scanProgress.isScanning
                ? null
                : () {
                    ref.read(mediaNotifierProvider.notifier).scanDevice();
                  },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: GlassPanel(
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(mediaSearchQueryProvider.notifier).state = val;
                    },
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search videos, tracks, artists...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      border: InputBorder.none,
                      icon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(mediaSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              // Filter Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Videos'),
                  Tab(text: 'Music'),
                  Tab(text: 'Recents'),
                  Tab(text: 'Favorites'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Scanning Progress Banner
          if (scanProgress.isScanning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surfaceElevated,
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Scanning storage (${scanProgress.filesFound} items found)...',
                      style: AppTypography.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Tab Contents
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Videos Tab (Folder view by default + flat list toggle)
                _buildVideoTab(videoFoldersAsync, videoListAsync, viewMode),
                _buildMediaList(audioListAsync, 'No music found'),
                _buildMediaList(recentListAsync, 'No recently played media'),
                _buildMediaList(favoriteListAsync, 'No favorites added yet'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTab(
    AsyncValue<List<MediaFolder>> foldersAsync,
    AsyncValue<List<MediaItem>> allVideosAsync,
    VideoViewMode viewMode,
  ) {
    return Column(
      children: [
        // View Mode Switcher Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                viewMode == VideoViewMode.folders ? 'Video Folders' : 'All Videos',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        ref.read(videoViewModeProvider.notifier).state = VideoViewMode.folders;
                      },
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: viewMode == VideoViewMode.folders ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 16,
                              color: viewMode == VideoViewMode.folders ? AppColors.primary : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Folders',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: viewMode == VideoViewMode.folders ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        ref.read(videoViewModeProvider.notifier).state = VideoViewMode.allVideos;
                      },
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: viewMode == VideoViewMode.allVideos ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.grid_view_rounded,
                              size: 16,
                              color: viewMode == VideoViewMode.allVideos ? AppColors.primary : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'All',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: viewMode == VideoViewMode.allVideos ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Body Content (Folders or Flat List)
        Expanded(
          child: viewMode == VideoViewMode.folders
              ? _buildFolderList(foldersAsync)
              : _buildMediaList(allVideosAsync, 'No videos found'),
        ),
      ],
    );
  }

  Widget _buildFolderList(AsyncValue<List<MediaFolder>> foldersAsync) {
    return foldersAsync.when(
      data: (folders) {
        if (folders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_rounded, size: 56, color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No video folders found', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan your device storage to discover your video folders.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  GlowingButton(
                    onPressed: () {
                      ref.read(mediaNotifierProvider.notifier).scanDevice();
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 18, color: Colors.black),
                        SizedBox(width: 8),
                        Text('Scan Device'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            await ref.read(mediaNotifierProvider.notifier).scanDevice();
          },
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 100),
            itemCount: folders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final folder = folders[index];
              return FolderCard(
                folder: folder,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FolderDetailScreen(folder: folder),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
        child: Text('Error loading folders: $e', style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  Widget _buildMediaList(AsyncValue<List<MediaItem>> asyncList, String emptyMessage) {
    return asyncList.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined, size: 56, color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(emptyMessage, style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan your device storage to discover local media files.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  GlowingButton(
                    onPressed: () {
                      ref.read(mediaNotifierProvider.notifier).scanDevice();
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 18, color: Colors.black),
                        SizedBox(width: 8),
                        Text('Scan Device'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            await ref.read(mediaNotifierProvider.notifier).scanDevice();
          },
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 100),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return MediaCard(
                item: item,
                onTap: () => _openMedia(item, items),
                onFavoriteToggle: () {
                  if (item.id != null) {
                    ref.read(mediaNotifierProvider.notifier).toggleFavorite(item.id!);
                  }
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('Error loading media: $e', style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  void _openMedia(MediaItem item, [List<MediaItem>? playlist]) {
    if (item.isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(mediaItem: item, playlist: playlist),
        ),
      );
    } else {
      ref.read(playbackControllerProvider.notifier).playMedia(item, playlist: playlist);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MusicPlayerScreen(mediaItem: item, playlist: playlist),
        ),
      );
    }
  }
}
