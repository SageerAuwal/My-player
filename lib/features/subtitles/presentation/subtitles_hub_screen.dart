import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/media_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glowing_button.dart';
import '../../../core/widgets/spatial_card.dart';
import '../../home/controller/media_providers.dart';
import '../../video/presentation/video_player_screen.dart';
import '../controller/subtitle_controller.dart';

class SubtitlesHubScreen extends ConsumerStatefulWidget {
  const SubtitlesHubScreen({super.key});

  @override
  ConsumerState<SubtitlesHubScreen> createState() => _SubtitlesHubScreenState();
}

class _SubtitlesHubScreenState extends ConsumerState<SubtitlesHubScreen> {
  MediaItem? _selectedVideo;

  @override
  Widget build(BuildContext context) {
    final videoListAsync = ref.watch(videoListProvider);
    final progress = ref.watch(transcriptionProgressProvider);
    final segments = ref.watch(subtitleSegmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Subtitles', style: AppTypography.displayMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
        children: [
          // On-Device Whisper Banner
          SpatialCard(
            padding: const EdgeInsets.all(18),
            hasGlow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.black, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Offline Whisper Engine', style: AppTypography.titleMedium),
                          SizedBox(height: 2),
                          Text('100% on-device AI speech-to-text', style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'AuraPlayer generates high-accuracy subtitles for your offline videos without internet access or data leaks.',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Transcription Progress Card if active
          if (progress.progress > 0 && !progress.isCompleted) ...[
            SpatialCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.primary,
              hasGlow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          progress.status,
                          style: AppTypography.titleMedium.copyWith(fontSize: 14),
                        ),
                      ),
                      Text(
                        '${(progress.progress * 100).toInt()}%',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.progress,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Transcribed Segments Preview if available
          if (segments.isNotEmpty && _selectedVideo != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GENERATED SUBTITLES (${segments.length})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.play_arrow, color: AppColors.primary, size: 18),
                  label: const Text('Play Video', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(mediaItem: _selectedVideo!),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SpatialCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: segments.take(3).map((seg) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${seg.start.inSeconds}s',
                            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            seg.text,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'SELECT A VIDEO TO TRANSCRIBE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          videoListAsync.when(
            data: (videos) {
              if (videos.isEmpty) {
                return SpatialCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.video_library_outlined, size: 44, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text('No videos found on device', style: AppTypography.titleMedium),
                        const SizedBox(height: 14),
                        GlowingButton(
                          onPressed: () {
                            ref.read(mediaNotifierProvider.notifier).scanDevice();
                          },
                          child: const Text('Scan Storage'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: videos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final video = videos[index];
                  final isSelected = _selectedVideo?.id == video.id;

                  return SpatialCard(
                    onTap: () {
                      setState(() => _selectedVideo = video);
                      ref.read(subtitleNotifierProvider.notifier).startTranscription(video);
                    },
                    padding: const EdgeInsets.all(12),
                    hasGlow: isSelected,
                    borderColor: isSelected ? AppColors.primary : null,
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.movie_outlined, color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.title,
                                style: AppTypography.titleMedium.copyWith(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(video.formattedSize, style: AppTypography.bodySmall),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderGlow),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: AppColors.primary, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'AI Subtitle',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}
