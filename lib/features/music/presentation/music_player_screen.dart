import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/media_item.dart';
import '../../../core/models/playback_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../home/controller/media_providers.dart';
import '../../video/controller/playback_controller.dart';

class MusicPlayerScreen extends ConsumerStatefulWidget {
  final MediaItem mediaItem;
  final List<MediaItem>? playlist;

  const MusicPlayerScreen({
    super.key,
    required this.mediaItem,
    this.playlist,
  });

  @override
  ConsumerState<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends ConsumerState<MusicPlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowAnimController;

  @override
  void initState() {
    super.initState();
    _glowAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Auto-play if not already playing this item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(playbackControllerProvider).currentItem;
      if (current?.path != widget.mediaItem.path) {
        ref.read(playbackControllerProvider.notifier).playMedia(widget.mediaItem, playlist: widget.playlist);
      }
    });
  }

  @override
  void dispose() {
    _glowAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackControllerProvider);
    final item = playbackState.currentItem ?? widget.mediaItem;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Now Playing', style: AppTypography.titleMedium),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              item.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: item.isFavorite ? AppColors.error : AppColors.textSecondary,
            ),
            onPressed: () {
              if (item.id != null) {
                ref.read(mediaNotifierProvider.notifier).toggleFavorite(item.id!);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const Spacer(),

              // Pulsing Album Art / Vinyl Disc
              AnimatedBuilder(
                animation: _glowAnimController,
                builder: (context, child) {
                  final glowRadius = playbackState.isPlaying
                      ? 20.0 + (_glowAnimController.value * 25.0)
                      : 10.0;

                  return Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.borderGlow, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(playbackState.isPlaying ? 0.35 : 0.1),
                          blurRadius: glowRadius,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceElevated,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          size: 44,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),

              // Title and Artist
              Text(
                item.title,
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                item.artist ?? 'Local Audio Track',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Position Scrubber
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.surfaceElevated,
                  thumbColor: AppColors.primary,
                ),
                child: Slider(
                  value: playbackState.progressPercentage,
                  onChanged: (val) {
                    final targetMs = (val * playbackState.duration.inMilliseconds).toInt();
                    ref.read(playbackControllerProvider.notifier).seekTo(
                          Duration(milliseconds: targetMs),
                        );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(playbackState.formattedPosition, style: AppTypography.bodySmall),
                    Text(playbackState.formattedDuration, style: AppTypography.bodySmall),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Controls Panel with Previous, Seek -10s, Play/Pause, Seek +10s, Next
              GlassPanel(
                borderRadius: 24,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Previous Track (⏮)
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, size: 34),
                      color: AppColors.textPrimary,
                      tooltip: 'Previous Track',
                      onPressed: () {
                        ref.read(playbackControllerProvider.notifier).playPrevious();
                      },
                    ),

                    // Seek -10s
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded, size: 24),
                      color: AppColors.textSecondary,
                      onPressed: () {
                        ref.read(playbackControllerProvider.notifier).seekRelative(-10);
                      },
                    ),

                    // Play / Pause glowing button
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGlow,
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        iconSize: 52,
                        icon: Icon(
                          playbackState.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          ref.read(playbackControllerProvider.notifier).togglePlayPause();
                        },
                      ),
                    ),

                    // Seek +10s
                    IconButton(
                      icon: const Icon(Icons.forward_10_rounded, size: 24),
                      color: AppColors.textSecondary,
                      onPressed: () {
                        ref.read(playbackControllerProvider.notifier).seekRelative(10);
                      },
                    ),

                    // Next Track (⏭)
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 34),
                      color: AppColors.textPrimary,
                      tooltip: 'Next Track',
                      onPressed: () {
                        ref.read(playbackControllerProvider.notifier).playNext();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Speed Switcher Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSpeedButton(ref, playbackState, 1.0),
                  const SizedBox(width: 8),
                  _buildSpeedButton(ref, playbackState, 1.25),
                  const SizedBox(width: 8),
                  _buildSpeedButton(ref, playbackState, 1.5),
                  const SizedBox(width: 8),
                  _buildSpeedButton(ref, playbackState, 2.0),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedButton(WidgetRef ref, PlaybackState state, double speed) {
    final isSelected = (state.playbackSpeed - speed).abs() < 0.05;
    return InkWell(
      onTap: () => ref.read(playbackControllerProvider.notifier).setPlaybackSpeed(speed),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Text(
          '${speed}x',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
