# AuraPlayer Product Requirements Document (PRD)

**Version:** 1.0 (MVP)  
**Status:** Approved Concept  
**Product:** AuraPlayer  
**Platform:** Android (first release)  
**Theme:** Spatial UI (Dark OLED-first)

---

# 1. Executive Summary

AuraPlayer is an offline-first AI media player designed for users who want premium video and music playback without advertisements or internet dependency.

The MVP focuses on one signature AI feature: **offline subtitle generation**.

Unlike traditional media players, AuraPlayer generates subtitles locally using an on-device AI model while maintaining privacy and supporting both video and music playback.

---

# 2. Vision

> "An intelligent offline media player that understands your media without sending your data to the cloud."

---

# 3. Goals

### Primary Goals

- Premium offline media player.
- AI-generated subtitles.
- Support both video and music.
- Modern Spatial UI.
- Zero advertisements.

### Non-Goals (MVP)

- AI summaries
- AI translation
- AI quizzes
- Cloud accounts
- Streaming services

---

# 4. Target Audience

- Students
- Movie lovers
- Music listeners
- Travelers
- Privacy-conscious users

---

# 5. Unique Selling Points

- 100% Offline
- No Ads
- AI Subtitle Generation
- Premium Spatial UI
- Supports both video and music

---

# 6. Design Language

## UI Style

**Spatial UI**

### Characteristics

- Floating controls
- Glass-like panels
- Layered depth
- Smooth animations
- Minimal distractions

## Theme

Dark OLED-first

### Color Palette

| Role | Color |
|------|--------|
| Background | #0B0F14 |
| Surface | #151A20 |
| Primary | #00D4C7 |
| Secondary | #00F5A0 |
| Text | #EDEDED |
| Secondary Text | #8A8A8A |

### Typography

- Inter
- Medium emphasis
- Rounded hierarchy

### Corner Radius

24px

---

# 7. Core User Experience

## Home

Tabs:

- Videos
- Music

Sections:

- Continue Watching
- Recent
- Favorites
- Folders

## Video Player

Features

- Floating playback controls
- Gesture navigation
- AI Subtitle button
- Picture-in-Picture
- Screen lock

## Music Player

Features

- Album artwork
- Playlist
- Shuffle
- Repeat
- Background playback
- Notification controls

---

# 8. AI Subtitle Feature

## Objective

Generate subtitles completely offline.

### Modes

| Mode | Description |
|------|-------------|
| Real-Time | Generates subtitles while playing |
| Generate | Creates a complete subtitle file before playback |

### User Flow

1. Open video.
2. Tap AI Subtitle.
3. Select mode.
4. Subtitle generation begins.
5. Subtitles appear.
6. `.srt` file is saved.

### Supported Subtitle Formats

- SRT
- ASS
- SSA
- VTT

### Storage

Generated subtitles are saved beside the video when possible, otherwise inside AuraPlayer's subtitle folder.

---

# 9. Supported Media Formats

## Video Containers

- MP4
- MKV
- AVI
- MOV
- WMV
- FLV
- WebM
- MPEG
- 3GP
- TS
- M2TS
- M4V

## Video Codecs

- H.264
- H.265
- AV1
- VP8
- VP9
- MPEG-2
- MPEG-4
- Theora

## Audio Formats

- MP3
- AAC
- M4A
- FLAC
- WAV
- OGG
- Opus
- WMA
- AIFF
- AMR
- MIDI

---

# 10. Functional Requirements

## Video Playback

- Play local videos
- Resume playback
- Hardware acceleration
- Playback speed
- Gesture controls
- PiP

## Music Playback

- Play local music
- Queue
- Shuffle
- Repeat
- Background playback

## Gestures

| Gesture | Action |
|----------|---------|
| Left swipe | Brightness |
| Right swipe | Volume |
| Horizontal swipe | Seek |
| Double tap | Skip 10 seconds |
| Pinch | Zoom |

---

# 11. AI Requirements

## Speech-to-Text

Engine:

Whisper.cpp

Requirements

- Offline
- Low latency
- Works during playback
- Saves SRT output

---

# 12. Non-Functional Requirements

## Performance

- App launch under 2 seconds
- Smooth 60 FPS animations
- Low battery usage

## Privacy

- No cloud processing
- No account required
- No telemetry by default

## Accessibility

- Large touch targets
- High contrast
- Subtitle size adjustment

---

# 13. Screen List

1. Splash
2. Home
3. Folder Browser
4. Video Player
5. Music Player
6. Playlist
7. AI Subtitle Bottom Sheet
8. Subtitle Settings
9. Playback Settings
10. App Settings

---

# 14. Technical Architecture

## Frontend

Flutter

## Playback Engine

media_kit (FFmpeg)

## AI

Whisper.cpp

## Storage

SQLite

## Permissions

- Media access
- Notifications
- Storage

---

# 15. Folder Structure

```
AuraPlayer/

Videos/
Music/
Subtitles/
Cache/
Settings/
```

---

# 16. Success Metrics

| Metric | Target |
|---------|---------|
| App startup | Under 2s |
| Subtitle generation | Under 3s initial response |
| Playback stability | 99% crash-free |
| Offline functionality | 100% |

---

# 17. Future Roadmap

### Version 1.1

- Subtitle editing
- Subtitle styling improvements

### Version 1.2

- OCR from paused frames

### Version 2.0

- AI summaries
- Smart bookmarks
- Transcript search

These features are intentionally postponed to keep the MVP focused.

---

# 18. Product Principles

AuraPlayer should always remain:

- Offline-first
- Privacy-first
- Ad-free
- Premium-looking
- Fast
- Easy to use
- Focused on media playback first and AI second
