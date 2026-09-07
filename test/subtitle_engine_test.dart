import 'package:flutter_test/flutter_test.dart';
import 'package:aura_player/core/models/subtitle_segment.dart';
import 'package:aura_player/services/ai_engine/srt_parser.dart';

void main() {
  test('SubtitleSegment timestamp formatting and containsPosition', () {
    const segment = SubtitleSegment(
      index: 1,
      start: Duration(seconds: 5),
      end: Duration(seconds: 10),
      text: 'Hello, AuraPlayer!',
    );

    expect(segment.containsPosition(const Duration(seconds: 4)), isFalse);
    expect(segment.containsPosition(const Duration(seconds: 5)), isTrue);
    expect(segment.containsPosition(const Duration(seconds: 7)), isTrue);
    expect(segment.containsPosition(const Duration(seconds: 10)), isTrue);
    expect(segment.containsPosition(const Duration(seconds: 11)), isFalse);

    final srtBlock = segment.toSrtBlock();
    expect(srtBlock, contains('00:00:05,000 --> 00:00:10,000'));
    expect(srtBlock, contains('Hello, AuraPlayer!'));
  });

  test('SrtParser parses multi-block SRT content', () {
    const srtText = '''
1
00:00:01,000 --> 00:00:04,500
First spoken sentence.

2
00:00:05,200 --> 00:00:09,800
Second spoken sentence with
multiple lines.
''';

    final segments = SrtParser.parse(srtText);
    expect(segments.length, 2);

    expect(segments[0].index, 1);
    expect(segments[0].start.inMilliseconds, 1000);
    expect(segments[0].end.inMilliseconds, 4500);
    expect(segments[0].text, 'First spoken sentence.');

    expect(segments[1].index, 2);
    expect(segments[1].start.inMilliseconds, 5200);
    expect(segments[1].end.inMilliseconds, 9800);
    expect(segments[1].text, 'Second spoken sentence with\nmultiple lines.');
  });

  test('SrtParser exports segments back to standard SRT format', () {
    const segments = [
      SubtitleSegment(
        index: 1,
        start: Duration(seconds: 0),
        end: Duration(seconds: 3),
        text: 'Segment one',
      ),
      SubtitleSegment(
        index: 2,
        start: Duration(seconds: 4),
        end: Duration(seconds: 8),
        text: 'Segment two',
      ),
    ];

    final exported = SrtParser.export(segments);
    final reParsed = SrtParser.parse(exported);

    expect(reParsed.length, 2);
    expect(reParsed[0].text, 'Segment one');
    expect(reParsed[1].text, 'Segment two');
    expect(reParsed[1].start.inSeconds, 4);
    expect(reParsed[1].end.inSeconds, 8);
  });

  test('SubtitleSegment.findSegmentAt performs O(log N) binary search lookup correctly', () {
    // Generate 1000 sequential segments
    final largeSegmentsList = List.generate(1000, (i) {
      return SubtitleSegment(
        index: i + 1,
        start: Duration(seconds: i * 5),
        end: Duration(seconds: (i * 5) + 4),
        text: 'Subtitle line $i',
      );
    });

    // Lookup segment at 42nd position (210s -> 214s)
    final found = SubtitleSegment.findSegmentAt(largeSegmentsList, const Duration(seconds: 212));
    expect(found, isNotNull);
    expect(found!.index, 43);
    expect(found.text, 'Subtitle line 42');

    // Lookup in gap (e.g. 214.5s)
    final gap = SubtitleSegment.findSegmentAt(largeSegmentsList, const Duration(milliseconds: 214500));
    expect(gap, isNull);
  });
}
