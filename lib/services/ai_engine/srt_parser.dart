import '../../core/models/subtitle_segment.dart';

class SrtParser {
  /// Parses standard SRT formatted string into a list of SubtitleSegments
  static List<SubtitleSegment> parse(String content) {
    final segments = <SubtitleSegment>[];
    if (content.trim().isEmpty) return segments;

    // Normalize line breaks
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final blocks = normalized.split('\n\n');

    int fallbackIndex = 1;

    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 2) continue;

      int index = fallbackIndex;
      String timeLine = '';
      final textLines = <String>[];

      // Check if first line is numeric index
      final parsedIndex = int.tryParse(lines[0].trim());
      if (parsedIndex != null && lines.length >= 2) {
        index = parsedIndex;
        timeLine = lines[1].trim();
        textLines.addAll(lines.sublist(2));
      } else {
        timeLine = lines[0].trim();
        textLines.addAll(lines.sublist(1));
      }

      if (!timeLine.contains('-->')) continue;

      final times = timeLine.split('-->');
      if (times.length != 2) continue;

      final startDuration = _parseTimestamp(times[0].trim());
      final endDuration = _parseTimestamp(times[1].trim());

      if (startDuration != null && endDuration != null) {
        final text = textLines.join('\n').trim();
        if (text.isNotEmpty) {
          segments.add(SubtitleSegment(
            index: index,
            start: startDuration,
            end: endDuration,
            text: text,
          ));
          fallbackIndex++;
        }
      }
    }

    return segments;
  }

  /// Exports a list of SubtitleSegments into standard SRT string
  static String export(List<SubtitleSegment> segments) {
    final buffer = StringBuffer();
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final formattedSeg = SubtitleSegment(
        index: i + 1,
        start: seg.start,
        end: seg.end,
        text: seg.text,
      );
      buffer.writeln(formattedSeg.toSrtBlock());
    }
    return buffer.toString();
  }

  static Duration? _parseTimestamp(String timestamp) {
    try {
      // Formats: 00:01:23,456 or 00:01:23.456 or 01:23,456
      final cleaned = timestamp.replaceAll(',', '.');
      final parts = cleaned.split(':');

      int hours = 0;
      int minutes = 0;
      double seconds = 0.0;

      if (parts.length == 3) {
        hours = int.tryParse(parts[0]) ?? 0;
        minutes = int.tryParse(parts[1]) ?? 0;
        seconds = double.tryParse(parts[2]) ?? 0.0;
      } else if (parts.length == 2) {
        minutes = int.tryParse(parts[0]) ?? 0;
        seconds = double.tryParse(parts[1]) ?? 0.0;
      } else {
        return null;
      }

      final totalMs = ((hours * 3600 + minutes * 60 + seconds) * 1000).toInt();
      return Duration(milliseconds: totalMs);
    } catch (_) {
      return null;
    }
  }
}
