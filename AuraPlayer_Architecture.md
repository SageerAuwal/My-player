# AuraPlayer Architecture Document (v1)

**Version:** 1.0  
**Status:** Approved Architecture  
**Product:** AuraPlayer  
**Platform:** Android (First Release)  
**Framework:** Flutter

---

# Table of Contents

1. Executive Overview
2. Architectural Principles
3. Technology Stack
4. High-Level Architecture
5. Layered Architecture
6. Feature-Based Project Structure
7. Core Modules
8. AI Subtitle Architecture
9. Media Support
10. Data Layer
11. State Management
12. Playback Flow
13. Gesture System
14. Android Integration
15. Performance Strategy
16. Security & Privacy
17. MVP Scope Lock

---

# 1. Executive Overview

AuraPlayer is an offline-first AI media player designed around a modular architecture that separates media playback from AI processing.

The most important architectural rule is:

> **The Media Engine must never wait for the AI Subtitle Engine.**

Video and music playback always have higher priority than subtitle generation, ensuring smooth performance even while AI runs in the background.

The architecture follows **Clean Architecture** combined with **Feature-Based Modular Design**, making it scalable while remaining lightweight enough for Flutter and AI coding tools.

---

# 2. Architectural Principles

AuraPlayer is built around six core principles.

- Offline-first
- Privacy-first
- No advertisements
- Modular architecture
- Smooth playback
- AI only where it improves playback

### Core Rule

```
Playback always runs independently.

AI processes subtitles asynchronously.
```

---

# 3. Technology Stack

| Layer | Technology |
|--------|------------|
| UI | Flutter |
| State Management | Riverpod |
| Playback Engine | media_kit |
| Codec Support | FFmpeg |
| AI Subtitle Engine | Whisper.cpp |
| Database | SQLite |
| File Discovery | MediaStore |
| Notifications | MediaSession |
| Picture-in-Picture | Android PiP |

---

# 4. High-Level Architecture

```text
AuraPlayer
│
├── Flutter Spatial UI
│
├── Riverpod Controllers
│
├── Media Engine
│   ├── Video Playback
│   ├── Music Playback
│   └── FFmpeg
│
├── AI Subtitle Engine
│   ├── Whisper.cpp
│   ├── Real-Time Subtitles
│   └── Subtitle Export
│
├── Local Storage
│   ├── SQLite
│   ├── Subtitle Files
│   └── Playback History
│
└── Android Services
    ├── MediaStore
    ├── Notifications
    ├── Audio Focus
    └── Picture-in-Picture
```

Each module communicates through controllers rather than directly calling one another.

---

# 5. Layered Architecture

AuraPlayer follows four layers.

```text
Presentation
      ↓
Application
      ↓
Infrastructure
      ↓
Android Platform
```

## Presentation Layer

Responsible for everything users interact with.

Includes:

- Spatial UI
- Screens
- Widgets
- Animations
- Bottom Sheets

No business logic belongs here.

---

## Application Layer

Controls application behavior.

Contains:

- Playback Controller
- Subtitle Controller
- Navigation Controller
- Playlist Controller

Riverpod manages communication between controllers and the UI.

---

## Infrastructure Layer

Provides system capabilities.

Includes:

- FFmpeg
- Whisper.cpp
- SQLite
- MediaStore
- Notification APIs

This layer never directly controls the UI.

---

## Android Platform

Uses native Android APIs.

- MediaStore
- AudioManager
- MediaSession
- PiP
- Storage Permissions

---

# 6. Feature-Based Project Structure

```text
AuraPlayer/
│
├── lib/
│
│   ├── core/
│   │   ├── theme/
│   │   ├── constants/
│   │   ├── widgets/
│   │   ├── animations/
│   │   └── utils/
│   │
│   ├── features/
│   │   ├── home/
│   │   ├── video_player/
│   │   ├── music_player/
│   │   ├── subtitles/
│   │   ├── folders/
│   │   ├── playlists/
│   │   └── settings/
│   │
│   ├── services/
│   │   ├── media_service/
│   │   ├── subtitle_service/
│   │   ├── storage_service/
│   │   └── notification_service/
│   │
│   ├── data/
│   │   ├── database/
│   │   ├── repositories/
│   │   └── models/
│   │
│   └── main.dart
│
└── android/
```

Every feature remains isolated, reducing coupling.

---

# 7. Core Modules

## Home Module

Responsibilities:

- Scan media
- Continue Watching
- Recent
- Favorites
- Folder browsing

---

## Video Player Module

Responsibilities:

- Local video playback
- Resume playback
- Hardware acceleration
- Playback speed
- Picture-in-Picture
- Gesture controls

Supported containers include:

- MP4
- MKV
- AVI
- MOV
- WebM
- TS
- M2TS
- MPEG
- FLV

---

## Music Player Module

Responsibilities:

- Music playback
- Albums
- Artists
- Queue
- Shuffle
- Repeat
- Background playback

Supported formats include:

- MP3
- AAC
- FLAC
- WAV
- OGG
- Opus
- WMA
- M4A

---

## Playlist Module

Responsibilities:

- Create playlists
- Edit playlists
- Queue management
- Repeat modes
- Shuffle modes

---

## Settings Module

Stores:

- Theme
- Playback preferences
- Subtitle settings
- Storage preferences

---

# 8. AI Subtitle Architecture

The AI Subtitle Engine is AuraPlayer's signature feature.

It operates independently from playback.

## Processing Pipeline

```text
Video
   │
   ▼
FFmpeg extracts audio
   │
   ▼
Whisper.cpp
   │
   ▼
Timestamped text
   │
   ▼
Subtitle Renderer
   │
   ▼
Save .srt
```

## Operating Modes

| Mode | Description |
|------|-------------|
| Real-Time | Generates subtitles during playback |
| Generate | Creates a complete subtitle before playback |

## Output Formats

- `.srt`
- `.ass`
- `.ssa`
- `.vtt`

Generated subtitles remain on the device.

---

# 9. Media Support

## Video Codecs

- H.264
- H.265
- AV1
- VP8
- VP9
- MPEG-2
- MPEG-4

## Audio Codecs

- AAC
- MP3
- FLAC
- Opus
- PCM
- Vorbis

FFmpeg provides broad codec compatibility.

---

# 10. Data Layer

SQLite stores application data.

## media_files

| Field | Purpose |
|-------|---------|
| id | Primary key |
| path | File location |
| type | Video or Music |
| duration | Media length |
| last_position | Resume position |

---

## subtitle_files

| Field | Purpose |
|-------|---------|
| id | Primary key |
| media_id | Linked media |
| path | Subtitle file |
| generated | AI generated flag |

---

## playback_history

| Field | Purpose |
|-------|---------|
| id | Primary key |
| media_path | Media file |
| position_ms | Resume time |
| last_played | Timestamp |

---

## settings

| Field | Purpose |
|-------|---------|
| key | Setting name |
| value | Stored value |

---

# 11. State Management

Riverpod coordinates application state.

```text
Riverpod
│
├── Home
├── Video
├── Music
├── Subtitles
└── Settings
```

Each feature owns its own providers.

Benefits:

- predictable state
- isolated updates
- easier testing

---

# 12. Playback Flow

Normal playback follows this sequence.

```text
User selects media
        │
        ▼
Media Library
        │
        ▼
Media Engine
        │
        ▼
Playback begins
        │
        ▼
UI updates
        │
        ▼
(Optional)
AI Subtitle Engine
        │
        ▼
Subtitles displayed
        │
        ▼
SRT saved
```

Playback never pauses for subtitle generation.

---

# 13. Gesture System

AuraPlayer uses a gesture layer above the video.

| Gesture | Action |
|----------|---------|
| Left Swipe | Brightness |
| Right Swipe | Volume |
| Horizontal Swipe | Seek |
| Double Tap | Skip 10 seconds |
| Pinch | Zoom |
| Long Press | Temporary Speed Boost |

The gesture layer sends commands to the Playback Controller instead of directly controlling FFmpeg.

---

# 14. Android Integration

Native Android capabilities improve the experience.

| Feature | API |
|----------|-----|
| Media discovery | MediaStore |
| Notifications | MediaSession |
| Lock screen | MediaStyle |
| PiP | Android PiP |
| Audio focus | AudioManager |

Required permissions include:

- READ_MEDIA_VIDEO
- READ_MEDIA_AUDIO
- POST_NOTIFICATIONS

---

# 15. Performance Strategy

Performance targets:

- App launch under 2 seconds
- Smooth 60 FPS animations
- Low battery usage

Optimization techniques:

- Hardware decoding
- Lazy thumbnail loading
- Subtitle caching
- Background isolates for Whisper.cpp
- Minimal UI rebuilds through Riverpod

---

# 16. Security & Privacy

AuraPlayer keeps all media local.

Rules:

- No cloud processing
- No account required
- No ads
- No telemetry by default
- Subtitle generation stays on-device
- User files never leave the device

---

# 17. MVP Scope Lock

The following features are locked for Version 1.

## Included

- Spatial UI
- Aurora Cyan branding
- Video playback
- Music playback
- Offline subtitle generation
- Real-time subtitles
- Subtitle export
- Hardware acceleration
- Gesture controls
- Background playback
- Picture-in-Picture
- Playlist support

## Excluded

- AI summaries
- AI translation
- AI chat
- Streaming services
- Cloud synchronization
- Online accounts

These exclusions intentionally keep AuraPlayer focused on delivering a premium offline media experience before expanding AI capabilities in future versions.

---

# Architecture Summary

AuraPlayer's architecture is designed around one fundamental idea:

> **Media playback is always the highest priority.**

The Media Engine, AI Subtitle Engine, UI Layer, and Android Services remain independent modules connected through Riverpod controllers. This keeps the application scalable, maintains smooth playback while subtitles are generated in the background, and provides a clean foundation for future features without requiring major architectural changes.