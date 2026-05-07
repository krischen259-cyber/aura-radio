import 'package:aura_radio/shared/utils/history_topic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isHistoryTopic', () {
    test('detects Chinese history-related topics', () {
      expect(isHistoryTopic('唐朝兴衰'), isTrue);
      expect(isHistoryTopic('古罗马帝国'), isTrue);
      expect(isHistoryTopic('丝绸之路'), isTrue);
    });

    test('returns false for unrelated topics', () {
      expect(isHistoryTopic(' Flutter 入门 '), isFalse);
      expect(isHistoryTopic(''), isFalse);
    });
  });
}
