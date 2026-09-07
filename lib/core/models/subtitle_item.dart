class SubtitleItem {
  final int? id;
  final int mediaId;
  final String path;
  final String language;
  final bool isAiGenerated;
  final String format;
  final int createdAt;

  const SubtitleItem({
    this.id,
    required this.mediaId,
    required this.path,
    this.language = 'en',
    this.isAiGenerated = false,
    this.format = 'srt',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'media_id': mediaId,
      'path': path,
      'language': language,
      'is_ai_generated': isAiGenerated ? 1 : 0,
      'format': format,
      'created_at': createdAt,
    };
  }

  factory SubtitleItem.fromMap(Map<String, dynamic> map) {
    return SubtitleItem(
      id: map['id'] as int?,
      mediaId: map['media_id'] as int,
      path: map['path'] as String,
      language: map['language'] as String? ?? 'en',
      isAiGenerated: (map['is_ai_generated'] as int? ?? 0) == 1,
      format: map['format'] as String? ?? 'srt',
      createdAt: map['created_at'] as int? ?? 0,
    );
  }
}
