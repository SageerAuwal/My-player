import 'package:flutter/material.dart';

/// AuraPlayer Dual Theme Palette:
/// 1. Night Mode: Spatial UI (3D & Depth) -> #0B0E14 Obsidian, #151A23 Surfaces, #7C5CFC Royal Violet
/// 2. Light Mode: Neomorphism (Soft & Clean) -> #EBF0F7 Porcelain Snow, #4F46E5 Royal Indigo
abstract class AppColors {
  // --- Dark Mode: Spatial UI (3D & Realistic Depth) ---
  static const Color darkBackground = Color(0xFF0B0E14); // Deep Obsidian #0B0E14
  static const Color darkSurface = Color(0xFF151A23);    // Elevated Plate #151A23
  static const Color darkSurfaceElevated = Color(0xFF1D2430);
  static const Color darkBorder = Color(0xFF1F2633);     // Sleek 3D Card Border
  static const Color darkBorderGlow = Color(0x667C5CFC); // 40% Violet Glow

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  // --- Light Mode: Neomorphism (Soft & Clean) ---
  static const Color lightBackground = Color(0xFFEBF0F7); // Porcelain Snow #EBF0F7
  static const Color lightSurface = Color(0xFFEBF0F7);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightShadowDark = Color(0x2BD0D7E2); // Soft bottom-right shadow
  static const Color lightShadowLight = Color(0xFFFFFFFF); // Soft top-left highlight
  static const Color lightBorder = Color(0xFFE2E8F0);

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextTertiary = Color(0xFF94A3B8);

  // --- Accent Branding (Royal Violet & Royal Indigo) ---
  static const Color violetPrimary = Color(0xFF7C5CFC); // Spatial UI Royal Violet
  static const Color violetSecondary = Color(0xFF6C47FF);
  static const Color indigoAccent = Color(0xFF4F46E5);   // Neomorphism Royal Indigo

  // Default shortcuts (pointing to spatial dark defaults)
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color surfaceElevated = darkSurfaceElevated;
  static const Color surfaceGlass = Color(0xCC151A23);
  static const Color primary = violetPrimary;
  static const Color secondary = violetSecondary;
  static const Color accent = indigoAccent;
  static const Color accentGlow = Color(0x4D7C5CFC);

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x26FFFFFF),
      Color(0x08FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textTertiary = darkTextTertiary;

  static const Color borderLight = darkBorder;
  static const Color borderGlow = darkBorderGlow;

  // Status & Feedback
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Official Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [violetPrimary, Color(0xFF9B82FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient spatialGradient = LinearGradient(
    colors: [
      Color(0xFF181E29),
      Color(0xFF131821),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
