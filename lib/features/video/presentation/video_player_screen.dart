import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../core/models/media_item.dart';
import '../../../core/models/playback_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/system_media/system_media_service.dart';
import '../../subtitles/controller/subtitle_controller.dart';
import '../../subtitles/presentation/widgets/in_player_subtitle_sheet.dart';
import '../../subtitles/presentation/widgets/subtitle_overlay.dart';
import '../controller/playback_controller.dart';

enum VideoOrientationMode {
  sensor,
  landscape,
  portrait,
}

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final MediaItem mediaItem;
  final List<MediaItem>? playlist;

  const VideoPlayerScreen({
    super.key,
    required this.mediaItem,
    this.playlist,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  // Orientation mode
  VideoOrientationMode _orientationMode = VideoOrientationMode.sensor;

  // Auto-hide controls timer
  Timer? _controlsTimer;

  // Gesture overlay indicators
  double? _gestureVolume;
  double? _gestureBrightness;
  int? _scrubDeltaSeconds;
  bool _showLeftDoubleTap = false;
  bool _showRightDoubleTap = false;
  bool _isFastForwarding = false;
  double _preFastForwardSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    // Enable immersive fullscreen and allow full rotation for video
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(systemMediaServiceProvider).setVideoActive(true);
      final current = ref.read(playbackControllerProvider).currentItem;
      if (current?.path != widget.mediaItem.path) {
        ref.read(playbackControllerProvider.notifier).playMedia(widget.mediaItem, playlist: widget.playlist);
      }
      _startControlsTimer();
    });
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && ref.read(playbackControllerProvider).isControlsVisible && !ref.read(playbackControllerProvider).isLocked) {
        ref.read(playbackControllerProvider.notifier).toggleControls();
      }
    });
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    ref.read(playbackServiceProvider).player.stop();
    ref.read(playbackControllerProvider.notifier).stop();
    ref.read(systemMediaServiceProvider).setVideoActive(false);
    // Restore portrait orientation and system UI for the rest of the app
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleOrientation() {
    setState(() {
      switch (_orientationMode) {
        case VideoOrientationMode.sensor:
          _orientationMode = VideoOrientationMode.landscape;
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
          _showToast('Screen: Landscape Locked');
          break;
        case VideoOrientationMode.landscape:
          _orientationMode = VideoOrientationMode.portrait;
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
          _showToast('Screen: Portrait Locked');
          break;
        case VideoOrientationMode.portrait:
          _orientationMode = VideoOrientationMode.sensor;
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
          _showToast('Screen: Auto-Rotate (Sensor)');
          break;
      }
    });
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        duration: const Duration(milliseconds: 900),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 40, right: 40),
      ),
    );
  }

  IconData _getOrientationIcon() {
    switch (_orientationMode) {
      case VideoOrientationMode.sensor:
        return Icons.screen_rotation_rounded;
      case VideoOrientationMode.landscape:
        return Icons.stay_primary_landscape_rounded;
      case VideoOrientationMode.portrait:
        return Icons.stay_primary_portrait_rounded;
    }
  }

  BoxFit _getBoxFit(PlayerAspectRatio ratio) {
    switch (ratio) {
      case PlayerAspectRatio.fit:
        return BoxFit.contain;
      case PlayerAspectRatio.fill:
        return BoxFit.fill;
      case PlayerAspectRatio.cover:
        return BoxFit.cover;
      case PlayerAspectRatio.ratio16x9:
        return BoxFit.contain;
      case PlayerAspectRatio.ratio4x3:
        return BoxFit.contain;
    }
  }

  @override
  Widget build(BuildContext context) {
    final playbackService = ref.watch(playbackServiceProvider);
    final playbackState = ref.watch(playbackControllerProvider);
    final isPipMode = ref.watch(isPipModeProvider);
    final item = playbackState.currentItem ?? widget.mediaItem;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        ref.read(playbackServiceProvider).player.stop();
        ref.read(playbackControllerProvider.notifier).stop();
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      child: isPipMode
          ? Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Video(
                  controller: playbackService.videoController,
                  fit: _getBoxFit(playbackState.aspectRatio),
                  controls: NoVideoControls,
                ),
              ),
            )
          : Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                fit: StackFit.expand,
                children: [
          // 1. Native Hardware-Accelerated Video Layer
          Center(
            child: Video(
              controller: playbackService.videoController,
              fit: _getBoxFit(playbackState.aspectRatio),
              controls: NoVideoControls,
            ),
          ),

          // Synchronized Subtitle Overlay
          const SubtitleOverlay(),

          // 2. Gesture Handling Layer
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              ref.read(playbackControllerProvider.notifier).toggleControls();
              final isVis = ref.read(playbackControllerProvider).isControlsVisible;
              if (isVis) {
                _startControlsTimer();
              } else {
                _controlsTimer?.cancel();
              }
            },
            onLongPressStart: (details) {
              if (playbackState.isLocked) return;
              _preFastForwardSpeed = playbackState.playbackSpeed;
              ref.read(playbackControllerProvider.notifier).setPlaybackSpeed(2.0);
              setState(() => _isFastForwarding = true);
              HapticFeedback.selectionClick();
            },
            onLongPressEnd: (details) {
              if (_isFastForwarding) {
                ref.read(playbackControllerProvider.notifier).setPlaybackSpeed(_preFastForwardSpeed);
                setState(() => _isFastForwarding = false);
              }
            },
            onLongPressCancel: () {
              if (_isFastForwarding) {
                ref.read(playbackControllerProvider.notifier).setPlaybackSpeed(_preFastForwardSpeed);
                setState(() => _isFastForwarding = false);
              }
            },
            onDoubleTapDown: (details) {
              final width = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < width / 2) {
                // Double tap left: seek -10s
                ref.read(playbackControllerProvider.notifier).seekRelative(-10);
                setState(() => _showLeftDoubleTap = true);
                Future.delayed(const Duration(milliseconds: 600), () {
                  if (mounted) setState(() => _showLeftDoubleTap = false);
                });
              } else {
                // Double tap right: seek +10s
                ref.read(playbackControllerProvider.notifier).seekRelative(10);
                setState(() => _showRightDoubleTap = true);
                Future.delayed(const Duration(milliseconds: 600), () {
                  if (mounted) setState(() => _showRightDoubleTap = false);
                });
              }
            },
            onVerticalDragUpdate: (details) {
              if (playbackState.isLocked) return;
              final width = MediaQuery.of(context).size.width;
              final delta = -details.primaryDelta! / 200.0;

              if (details.globalPosition.dx < width / 2) {
                // Left half: Brightness
                final current = _gestureBrightness ?? playbackState.brightness;
                final next = (current + delta).clamp(0.0, 1.0);
                ref.read(playbackControllerProvider.notifier).setBrightness(next);
                setState(() => _gestureBrightness = next);
              } else {
                // Right half: Volume
                final current = _gestureVolume ?? playbackState.volume;
                final next = (current + delta).clamp(0.0, 1.0);
                ref.read(playbackControllerProvider.notifier).setVolume(next);
                setState(() => _gestureVolume = next);
              }
            },
            onVerticalDragEnd: (_) {
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) {
                  setState(() {
                    _gestureVolume = null;
                    _gestureBrightness = null;
                  });
                }
              });
            },
            onHorizontalDragUpdate: (details) {
              if (playbackState.isLocked) return;
              final deltaSeconds = (details.primaryDelta! * 0.5).toInt();
              setState(() {
                _scrubDeltaSeconds = (_scrubDeltaSeconds ?? 0) + deltaSeconds;
              });
            },
            onHorizontalDragEnd: (_) {
              if (_scrubDeltaSeconds != null && _scrubDeltaSeconds != 0) {
                ref.read(playbackControllerProvider.notifier).seekRelative(_scrubDeltaSeconds!);
              }
              setState(() => _scrubDeltaSeconds = null);
            },
          ),

          // 3. Double-Tap Seek Animations
          if (_showLeftDoubleTap)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(left: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fast_rewind_rounded, color: AppColors.primary, size: 36),
                    Text('-10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          if (_showRightDoubleTap)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(right: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fast_forward_rounded, color: AppColors.primary, size: 36),
                    Text('+10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          // 4. Long-Press 2X Speed Indicator
          if (_isFastForwarding)
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fast_forward_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 6),
                      Text(
                        '2X SPEED',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Gesture Side HUDs (Brightness Left, Volume Right)
          if (_gestureBrightness != null)
            _buildSideHud(
              icon: Icons.brightness_6_rounded,
              label: 'Brightness',
              value: _gestureBrightness!,
              isLeft: true,
            ),

          if (_gestureVolume != null)
            _buildSideHud(
              icon: _gestureVolume! > 0.5
                  ? Icons.volume_up_rounded
                  : (_gestureVolume! > 0 ? Icons.volume_down_rounded : Icons.volume_mute_rounded),
              label: 'Volume',
              value: _gestureVolume!,
              isLeft: false,
            ),

          if (_scrubDeltaSeconds != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGlow),
                ),
                child: Text(
                  _scrubDeltaSeconds! >= 0 ? '+${_scrubDeltaSeconds}s' : '${_scrubDeltaSeconds}s',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // 5. Buffering Spinner
          if (playbackState.isBuffering)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),

          // 6. Ultra-Slim Top Action Bar
          if (playbackState.isControlsVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          onPressed: () {
                            ref.read(playbackServiceProvider).player.stop();
                            ref.read(playbackControllerProvider.notifier).stop();
                            SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // CC / Subtitles Toggle & Generator
                        IconButton(
                          icon: Icon(
                            Icons.closed_caption_rounded,
                            size: 22,
                            color: (ref.watch(isSubtitlesEnabledProvider) && ref.watch(subtitleSegmentsProvider).isNotEmpty)
                                ? AppColors.primary
                                : Colors.white,
                          ),
                          tooltip: 'Subtitles & AI',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          onPressed: () {
                            InPlayerSubtitleSheet.show(context, item);
                          },
                        ),
                        // Aspect Ratio Toggle
                        IconButton(
                          icon: const Icon(Icons.aspect_ratio_rounded, color: Colors.white, size: 20),
                          tooltip: 'Aspect Ratio',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          onPressed: () => _cycleAspectRatio(ref, playbackState.aspectRatio),
                        ),
                        // Floating PiP Pop-up Button
                        IconButton(
                          icon: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white, size: 20),
                          tooltip: 'Floating Pop-up',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          onPressed: () async {
                            await ref.read(systemMediaServiceProvider).enterPiP();
                          },
                        ),
                        // Screen Rotation Toggle
                        IconButton(
                          icon: Icon(_getOrientationIcon(), color: Colors.white, size: 20),
                          tooltip: 'Screen Rotation',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          onPressed: _toggleOrientation,
                        ),
                        // Screen Lock Toggle
                        IconButton(
                          icon: Icon(
                            playbackState.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                            size: 20,
                            color: playbackState.isLocked ? AppColors.primary : Colors.white,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          onPressed: () {
                            ref.read(playbackControllerProvider.notifier).toggleLock();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 7. Ultra-Slim Bottom Controls Bar
          if (playbackState.isControlsVisible && !playbackState.isLocked)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.88),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0, top: 4.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Compact Scrubber Row with inline Timestamps
                        Row(
                          children: [
                            Text(
                              playbackState.formattedPosition,
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2.5,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                  activeTrackColor: AppColors.primary,
                                  inactiveTrackColor: Colors.white24,
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
                            ),
                            Text(
                              playbackState.formattedDuration,
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),

                        // Ultra-Slim Control Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Speed Chip Button
                            InkWell(
                              onTap: () => _showSpeedDialog(context, ref, playbackState.playbackSpeed),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${playbackState.playbackSpeed}x',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Previous Video (⏮)
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded, size: 24),
                              color: Colors.white,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              tooltip: 'Previous Video',
                              onPressed: () {
                                ref.read(playbackControllerProvider.notifier).playPrevious();
                              },
                            ),

                            // Seek -10s
                            IconButton(
                              icon: const Icon(Icons.replay_10_rounded, size: 22),
                              color: Colors.white70,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              onPressed: () {
                                ref.read(playbackControllerProvider.notifier).seekRelative(-10);
                              },
                            ),
                            const SizedBox(width: 8),

                            // Play / Pause Circle
                            InkWell(
                              onTap: () {
                                ref.read(playbackControllerProvider.notifier).togglePlayPause();
                              },
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  playbackState.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Seek +10s
                            IconButton(
                              icon: const Icon(Icons.forward_10_rounded, size: 22),
                              color: Colors.white70,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              onPressed: () {
                                ref.read(playbackControllerProvider.notifier).seekRelative(10);
                              },
                            ),

                            // Next Video (⏭)
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded, size: 24),
                              color: Colors.white,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              tooltip: 'Next Video',
                              onPressed: () {
                                ref.read(playbackControllerProvider.notifier).playNext();
                              },
                            ),
                            const SizedBox(width: 16),

                            // Subtitle Toggle Icon
                            IconButton(
                              icon: Icon(
                                ref.watch(isSubtitlesEnabledProvider) ? Icons.subtitles_rounded : Icons.subtitles_off_rounded,
                                color: ref.watch(isSubtitlesEnabledProvider) ? AppColors.primary : Colors.white70,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              tooltip: 'Toggle AI Subtitles',
                              onPressed: () {
                                final current = ref.read(isSubtitlesEnabledProvider);
                                ref.read(isSubtitlesEnabledProvider.notifier).state = !current;
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildSideHud({
    required IconData icon,
    required String label,
    required double value,
    required bool isLeft,
  }) {
    return Align(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(left: isLeft ? 32 : 0, right: !isLeft ? 32 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 12),
            Container(
              width: 6,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(3),
              ),
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 6,
                height: 100 * value.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(value * 100).toInt()}%',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cycleAspectRatio(WidgetRef ref, PlayerAspectRatio current) {
    const nextRatios = [
      PlayerAspectRatio.fit,
      PlayerAspectRatio.cover,
      PlayerAspectRatio.fill,
    ];
    final nextIndex = (nextRatios.indexOf(current) + 1) % nextRatios.length;
    ref.read(playbackControllerProvider.notifier).setAspectRatio(nextRatios[nextIndex]);
  }

  void _showSpeedDialog(BuildContext context, WidgetRef ref, double currentSpeed) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Playback Speed', style: AppTypography.titleLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: speeds.map((s) {
                    final isSelected = (currentSpeed - s).abs() < 0.05;
                    return ChoiceChip(
                      label: Text('${s}x'),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withOpacity(0.25),
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.borderLight,
                      ),
                      onSelected: (_) {
                        ref.read(playbackControllerProvider.notifier).setPlaybackSpeed(s);
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
