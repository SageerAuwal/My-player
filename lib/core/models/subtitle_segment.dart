class SubtitleSegment {
  final int index;
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleSegment({
    required this.index,
    required this.start,
    required this.end,
    required this.text,
  });

  bool containsPosition(Duration position) {
    return position >= start && position <= end;
  }

  /// High-performance O(log N) binary search to find the active subtitle segment
  static SubtitleSegment? findSegmentAt(List<SubtitleSegment> segments, Duration position) {
    if (segments.isEmpty) return null;

    int low = 0;
    int high = segments.length - 1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final seg = segments[mid];

      if (seg.containsPosition(position)) {
        return seg;
      } else if (position < seg.start) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    return null;
  }

  String toSrtBlock() {
    return '$index\n${_formatSrtTimestamp(start)} --> ${_formatSrtTimestamp(end)}\n$text\n';
  }

  static String _formatSrtTimestamp(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds,$milliseconds';
  }
}
