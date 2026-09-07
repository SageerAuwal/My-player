import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/playback_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/spatial_card.dart';
import '../../home/controller/media_providers.dart';
import '../controller/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final seekStep = ref.watch(seekStepDurationProvider);
    final defaultAspect = ref.watch(defaultAspectRatioProvider);
    final autoPlayNext = ref.watch(autoPlayNextProvider);
    final backgroundPlayback = ref.watch(backgroundPlaybackProvider);
    final cacheSizeAsync = ref.watch(cacheSizeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: AppTypography.displayMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        children: [
          // Branding Header Card
          SpatialCard(
            padding: const EdgeInsets.all(20),
            hasGlow: true,
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 14,
                        spreadRadius: 2,
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
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Aura', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('Player', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Play • Listen • Understand',
                        style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 2),
                      Text('Version 1.0.0 • Offline First', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 1. Appearance & Theme
          _buildSectionHeader('APPEARANCE & THEME'),
          const SizedBox(height: 8),
          SpatialCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingRow(
                  icon: Icons.palette_outlined,
                  title: 'App Visual Theme',
                  subtitle: themeMode == ThemeMode.dark
                      ? 'Spatial UI (3D & Obsidian Night)'
                      : themeMode == ThemeMode.light
                          ? 'Neomorphism (Soft Light)'
                          : 'Follow System',
                  trailing: DropdownButton<ThemeMode>(
                    value: themeMode,
                    dropdownColor: AppColors.surfaceElevated,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('🌙 Spatial 3D (Dark)', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('☀️ Neomorphism (Light)', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('⚙️ System Auto', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      ),
                    ],
                    onChanged: (newMode) {
                      if (newMode != null) {
                        ref.read(themeModeProvider.notifier).state = newMode;
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Playback Settings
          _buildSectionHeader('PLAYBACK PREFERENCES'),
          const SizedBox(height: 8),
          SpatialCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Seek Step Duration
                _buildSettingRow(
                  icon: Icons.fast_forward_rounded,
                  title: 'Seek Step Duration',
                  subtitle: 'Skip forward/backward step: ${seekStep}s',
                  trailing: DropdownButton<int>(
                    value: seekStep,
                    dropdownColor: AppColors.surfaceElevated,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5s', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                      DropdownMenuItem(value: 10, child: Text('10s', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                      DropdownMenuItem(value: 15, child: Text('15s', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                      DropdownMenuItem(value: 30, child: Text('30s', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(seekStepDurationProvider.notifier).state = val;
                      }
                    },
                  ),
                ),
                const Divider(color: AppColors.borderLight, height: 24),

                // Default Aspect Ratio
                _buildSettingRow(
                  icon: Icons.aspect_ratio_rounded,
                  title: 'Default Video Aspect Ratio',
                  subtitle: defaultAspect == PlayerAspectRatio.fit
                      ? 'Fit to Screen (Original)'
                      : defaultAspect == PlayerAspectRatio.fill
                          ? 'Stretch to Fill'
                          : 'Zoom / Cover',
                  trailing: DropdownButton<PlayerAspectRatio>(
                    value: defaultAspect,
                    dropdownColor: AppColors.surfaceElevated,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    items: const [
                      DropdownMenuItem(value: PlayerAspectRatio.fit, child: Text('Fit Screen', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                      DropdownMenuItem(value: PlayerAspectRatio.fill, child: Text('Stretch Fill', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                      DropdownMenuItem(value: PlayerAspectRatio.cover, child: Text('Zoom Cover', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(defaultAspectRatioProvider.notifier).state = val;
                      }
                    },
                  ),
                ),
                const Divider(color: AppColors.borderLight, height: 24),

                // Auto-Play Next Media
                _buildSettingRow(
                  icon: Icons.queue_play_next_rounded,
                  title: 'Auto-Play Next Media',
                  subtitle: 'Automatically advance to next video/song',
                  trailing: Switch(
                    value: autoPlayNext,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      ref.read(autoPlayNextProvider.notifier).state = val;
                    },
                  ),
                ),
                const Divider(color: AppColors.borderLight, height: 24),

                // Background Playback
                _buildSettingRow(
                  icon: Icons.headset_rounded,
                  title: 'Background Audio Playback',
                  subtitle: 'Keep playing audio when switching apps',
                  trailing: Switch(
                    value: backgroundPlayback,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      ref.read(backgroundPlaybackProvider.notifier).state = val;
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Storage & Cache Management
          _buildSectionHeader('STORAGE & MAINTENANCE'),
          const SizedBox(height: 8),
          SpatialCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Rescan Storage
                InkWell(
                  onTap: () {
                    ref.read(mediaNotifierProvider.notifier).scanDevice();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rescanning device storage for new media...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: _buildSettingRow(
                    icon: Icons.refresh_rounded,
                    title: 'Rescan Device Storage',
                    subtitle: 'Re-index media files from storage',
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ),
                ),
                const Divider(color: AppColors.borderLight, height: 24),

                // Clear Temporary Cache
                InkWell(
                  onTap: () async {
                    final deleted = await CacheCleaner.clearCache();
                    ref.invalidate(cacheSizeProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(deleted > 0 ? 'Cleaned ${(deleted / 1024).toStringAsFixed(1)} KB of cache!' : 'Cache is already clean!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: _buildSettingRow(
                    icon: Icons.cleaning_services_rounded,
                    title: 'Clear Temporary Cache',
                    subtitle: 'Temporary thumbnail and decoding cache: ${cacheSizeAsync.value ?? "Calculating..."}',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderGlow),
                      ),
                      child: const Text('Clean', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.bodySmall),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
