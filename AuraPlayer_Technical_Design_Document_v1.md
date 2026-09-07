# AuraPlayer Technical Design Document (v1)

## Architecture

Frontend:
- Flutter

Playback:
- media_kit
- FFmpeg backend

AI:
- Whisper.cpp

Database:
- SQLite

State:
- Riverpod

## Project Structure

```
lib/
  core/
  features/
    home/
    video/
    music/
    subtitles/
    settings/
  services/
  widgets/
```

## Modules

### Home
- Media scan
- Recent
- Favorites

### Video
- Playback
- Gestures
- Resume

### Music
- Queue
- Shuffle
- Background

### AI Subtitle
- Whisper.cpp wrapper
- Real-time processing
- SRT export

## Subtitle Pipeline

1. Extract audio.
2. Feed Whisper.cpp.
3. Receive timestamped text.
4. Display subtitle.
5. Save SRT.

## Database Schema

### media_files
- id
- path
- type
- duration
- last_position

### subtitle_files
- id
- media_id
- path
- generated

### settings
- key
- value

## FFmpeg Responsibilities
- Hardware decoding
- Audio extraction
- Codec support
- Container support

## Supported Formats

Video:
MP4, MKV, AVI, MOV, WebM, TS

Audio:
MP3, FLAC, AAC, WAV, OGG, Opus

## Permissions

Android:
- READ_MEDIA_VIDEO
- READ_MEDIA_AUDIO
- POST_NOTIFICATIONS

## Performance

- 60 FPS UI
- Lazy media loading
- Thumbnail caching
- Background subtitle processing

## Error Handling

Cases:
- Unsupported codec
- Corrupt media
- Subtitle generation failure
- Permission denied

Each shows a friendly retry dialog.

## Testing

### Unit
- Subtitle generation wrapper
- Database
- Playback state

### Widget
- Controls
- Bottom sheets

### Integration
- Video playback
- Music playback
- SRT export

## Release Plan

Alpha:
- Core playback

Beta:
- AI Subtitle

v1:
- Stable offline player
- Video + Music
- Spatial UI
