enum MediaType {
  video,
  audio,
}

class MediaItem {
  final int? id;
  final String path;
  final String title;
  final String? artist;
  final String? album;
  final int durationMs;
  final MediaType type;
  final int sizeBytes;
  final int dateAdded;
  final int lastPositionMs;
  final bool isFavorite;
  final String? thumbnailPath;

  const MediaItem({
    this.id,
    required this.path,
    required this.title,
    this.artist,
    this.album,
    required this.durationMs,
    required this.type,
    required this.sizeBytes,
    required this.dateAdded,
    this.lastPositionMs = 0,
    this.isFavorite = false,
    this.thumbnailPath,
  });

  bool get isVideo => type == MediaType.video;
  bool get isAudio => type == MediaType.audio;

  String get formattedDuration {
    final totalSeconds = durationMs ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }

  double get progressPercentage {
    if (durationMs <= 0) return 0.0;
    return (lastPositionMs / durationMs).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'path': path,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': durationMs,
      'type': type.name,
      'size': sizeBytes,
      'date_added': dateAdded,
      'last_position': lastPositionMs,
      'is_favorite': isFavorite ? 1 : 0,
      'thumbnail_path': thumbnailPath,
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] as int?,
      path: map['path'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      durationMs: map['duration'] as int? ?? 0,
      type: (map['type'] as String?) == 'audio' ? MediaType.audio : MediaType.video,
      sizeBytes: map['size'] as int? ?? 0,
      dateAdded: map['date_added'] as int? ?? 0,
      lastPositionMs: map['last_position'] as int? ?? 0,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      thumbnailPath: map['thumbnail_path'] as String?,
    );
  }

  MediaItem copyWith({
    int? id,
    String? path,
    String? title,
    String? artist,
    String? album,
    int? durationMs,
    MediaType? type,
    int? sizeBytes,
    int? dateAdded,
    int? lastPositionMs,
    bool? isFavorite,
    String? thumbnailPath,
  }) {
    return MediaItem(
      id: id ?? this.id,
      path: path ?? this.path,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      durationMs: durationMs ?? this.durationMs,
      type: type ?? this.type,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      dateAdded: dateAdded ?? this.dateAdded,
      lastPositionMs: lastPositionMs ?? this.lastPositionMs,
      isFavorite: isFavorite ?? this.isFavorite,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}
