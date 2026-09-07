# AuraPlayer 🎵🎬🤖

> **Play • Listen • Understand**  
> Premium offline-first AI media player with Spatial UI and on-device Whisper subtitle generation.

---

## 🌟 Key Highlights

* **100% Offline & Privacy-First:** Zero network dependencies, zero telemetry, zero advertisements.
* **On-Device Whisper AI Engine:** Asynchronous local speech-to-text subtitle generation with millisecond-accurate sync and `.srt` export.
* **Decoupled Playback Architecture:** Video & music playback never wait for AI processing (steady 60/120 FPS).
* **Hardware-Accelerated Engine:** Built on `media_kit` (libmpv + Android MediaCodec) with a 32MB adaptive stream buffer.
* **Spatial UI (OLED Dark-First):** Frosted glass panels, Aurora Cyan (`#00D4C7`) and Spring Green (`#00F5A0`) glow accents, and gesture HUD overlays.

---

## 📐 Architecture & Project Structure

AuraPlayer is built using **Clean Architecture** combined with **Feature-First Modular Design**:

```text
lib/
├── app.dart                   # Main navigation shell & floating bottom bar
├── main.dart                  # MediaKit initialization & Riverpod ProviderScope
├── core/
│   ├── models/                # MediaItem, SubtitleItem, SubtitleSegment, PlaybackState
│   ├── theme/                 # AppColors (OLED dark), AppTypography, AppTheme
│   └── widgets/               # GlassPanel, SpatialCard, GlowingButton
├── features/
│   ├── home/                  # Media library (Videos, Music, Recents, Favorites) & search
│   ├── video/                 # Hardware video player, gesture HUDs, aspect ratios, scrubber
│   ├── music/                 # Pulsing vinyl glow audio player, seek bar, mini-player
│   ├── subtitles/             # Offline Whisper AI transcription hub, sync overlay, SRT exporter
│   └── settings/              # Engine configuration, offline status, storage rescan
└── services/
    ├── ai_engine/             # WhisperEngine (asynchronous transcription) & SrtParser
    ├── database/              # AppDatabase (Indexed SQLite schemas)
    ├── media_scanner/         # Android MediaStore & storage scanner service
    └── player/                # PlaybackService (media_kit hardware controller)
```

---

## 🎮 Video Gesture System

| Gesture | Action |
| :--- | :--- |
| **Double-Tap Left** | Seek `-10s` with animated HUD circle |
| **Double-Tap Right** | Seek `+10s` with animated HUD circle |
| **Vertical Swipe (Left Half)** | Smooth on-screen Brightness override HUD |
| **Vertical Swipe (Right Half)** | Smooth on-screen Volume override HUD |
| **Horizontal Swipe** | Fine velocity scrubbing with delta time HUD (`+0:15`, `-0:30`) |
| **Single Tap** | Toggle floating spatial controls (auto-hides after 4s) |

---

## 🛠️ Tech Stack

* **Framework:** Flutter (Android minSdk 24+)
* **State Management:** Riverpod (`StateNotifier`, `AsyncNotifier`, `Provider`)
* **Media Playback:** `media_kit`, `media_kit_video`, `media_kit_libs_android_video`
* **Local Persistence:** `sqflite` (Indexed SQLite database)
* **AI Subtitle Engine:** On-device `whisper.cpp` asynchronous pipeline
* **Permissions:** `permission_handler` (Android 13+ `READ_MEDIA_*`)

---

## 🧪 Testing & Verification

Run the automated test suite:
```bash
flutter test
```

Run static analysis:
```bash
flutter analyze
```

Build release APK:
```bash
flutter build apk --release
```
