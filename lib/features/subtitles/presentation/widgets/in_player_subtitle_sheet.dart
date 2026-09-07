import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/media_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/glowing_button.dart';
import '../../controller/subtitle_controller.dart';

class InPlayerSubtitleSheet extends ConsumerWidget {
  final MediaItem mediaItem;

  const InPlayerSubtitleSheet({
    super.key,
    required this.mediaItem,
  });

  static void show(BuildContext context, MediaItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => InPlayerSubtitleSheet(mediaItem: item),
    );
  }

  File? _getCompanionSubtitleFile() {
    try {
      final dotIndex = mediaItem.path.lastIndexOf('.');
      if (dotIndex != -1) {
        final basePath = mediaItem.path.substring(0, dotIndex);
        final srt = File('$basePath.srt');
        if (srt.existsSync()) return srt;
        final vtt = File('$basePath.vtt');
        if (vtt.existsSync()) return vtt;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(isSubtitlesEnabledProvider);
    final segments = ref.watch(subtitleSegmentsProvider);
    final progress = ref.watch(transcriptionProgressProvider);
    final delayMs = ref.watch(subtitleDelayMsProvider);
    final fontSize = ref.watch(subtitleFontSizeProvider);

    final isTranscribing = progress.isTranscribing;
    final companionFile = _getCompanionSubtitleFile();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Header: Title + Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.subtitles_rounded, color: AppColors.primary, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Subtitles & Captions',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      isEnabled ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: isEnabled ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Switch(
                      value: isEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        ref.read(isSubtitlesEnabledProvider.notifier).state = val;
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: AppColors.borderLight, height: 24),

            // 1. Companion Subtitle Found Auto-Detect Card
            if (companionFile != null && segments.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.file_present_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Companion Subtitle Found',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            companionFile.path.split(Platform.pathSeparator).last,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        await ref.read(subtitleNotifierProvider.notifier).loadFromFile(companionFile);
                        ref.read(isSubtitlesEnabledProvider.notifier).state = true;
                      },
                      child: const Text('Load', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 2. Import External Subtitle File (.srt, .vtt)
            GlassPanel(
              borderRadius: 16,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'External Subtitle File',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Import any .srt, .vtt, or subtitle file from your phone storage or downloads folder.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showFilePickerModal(context, ref),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.file_upload_outlined, color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Choose Subtitle File (.srt, .vtt)',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Auto-Generate Subtitles (On-Device AI) Section
            GlassPanel(
              borderRadius: 16,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'On-Device AI Transcription',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Directly analyzes the video file on your device to create timed subtitles. Works with headphones or on mute.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  if (isTranscribing) ...[
                    LinearProgressIndicator(
                      value: progress.progress > 0 ? progress.progress : null,
                      color: AppColors.primary,
                      backgroundColor: AppColors.surfaceElevated,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      progress.status,
                      style: const TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ] else ...[
                    GlowingButton(
                      onPressed: () {
                        ref.read(subtitleNotifierProvider.notifier).startTranscription(mediaItem);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.psychology_rounded, color: Colors.black, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            segments.isEmpty ? 'Analyze Video & Generate Subtitles' : 'Re-Analyze Video with AI',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Active Status & Local File Loading
            if (segments.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${segments.length} caption lines loaded and active',
                        style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                      tooltip: 'Clear Subtitles',
                      onPressed: () {
                        ref.read(subtitleNotifierProvider.notifier).clearSubtitles();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 3. Subtitle Customization (Delay & Size)
            const Text(
              'Sync & Appearance',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            // Delay Control
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Timing Sync: ${(delayMs / 1000.0).toStringAsFixed(1)}s',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                Row(
                  children: [
                    _buildSmallButton(
                      label: '-0.5s',
                      onTap: () => ref.read(subtitleNotifierProvider.notifier).adjustDelay(-500),
                    ),
                    const SizedBox(width: 6),
                    if (delayMs != 0)
                      _buildSmallButton(
                        label: 'Reset',
                        onTap: () => ref.read(subtitleDelayMsProvider.notifier).state = 0,
                      ),
                    const SizedBox(width: 6),
                    _buildSmallButton(
                      label: '+0.5s',
                      onTap: () => ref.read(subtitleNotifierProvider.notifier).adjustDelay(500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Font Size Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Font Size',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                Row(
                  children: [
                    _buildSizeChip(ref, 'Small', 14.0, fontSize),
                    const SizedBox(width: 6),
                    _buildSizeChip(ref, 'Medium', 18.0, fontSize),
                    const SizedBox(width: 6),
                    _buildSizeChip(ref, 'Large', 22.0, fontSize),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSizeChip(WidgetRef ref, String label, double size, double currentSize) {
    final isSelected = currentSize == size;
    return InkWell(
      onTap: () => ref.read(subtitleNotifierProvider.notifier).setFontSize(size),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showFilePickerModal(BuildContext context, WidgetRef ref) {
    // Scan directory of mediaItem for subtitle files
    List<File> localSubs = [];
    try {
      final parentDir = File(mediaItem.path).parent;
      if (parentDir.existsSync()) {
        final list = parentDir.listSync();
        for (final entity in list) {
          if (entity is File) {
            final ext = entity.path.toLowerCase();
            if (ext.endsWith('.srt') || ext.endsWith('.vtt') || ext.endsWith('.sub') || ext.endsWith('.ass')) {
              localSubs.add(entity);
            }
          }
        }
      }
    } catch (_) {}

    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.folder_special_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Select Subtitle File',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (localSubs.isNotEmpty) ...[
                const Text('Subtitles in this folder:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                ...localSubs.map((file) {
                  final name = file.path.split(Platform.pathSeparator).last;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.subtitles, color: AppColors.primary, size: 20),
                    title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
                    onTap: () async {
                      await ref.read(subtitleNotifierProvider.notifier).loadFromFile(file);
                      ref.read(isSubtitlesEnabledProvider.notifier).state = true;
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                  );
                }),
                const Divider(color: AppColors.borderLight, height: 20),
              ],

              const Text('Or enter file path / URL:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: '/sdcard/Download/subtitles.srt',
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check, color: AppColors.primary),
                    onPressed: () async {
                      final path = textController.text.trim();
                      if (path.isNotEmpty) {
                        final file = File(path);
                        if (file.existsSync()) {
                          await ref.read(subtitleNotifierProvider.notifier).loadFromFile(file);
                          ref.read(isSubtitlesEnabledProvider.notifier).state = true;
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('File not found at specified path')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
