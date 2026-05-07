import 'package:aura_radio/shared/utils/sentence_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SentenceBuffer', () {
    test('returns completed sentences when delimiter arrives', () {
      final b = SentenceBuffer();
      expect(b.pushChunk('Hello '), isEmpty);
      expect(b.pushChunk('world. '), equals(['Hello world.']));
      expect(b.pushChunk('Next!'), equals(['Next!']));
      expect(b.flushRemainder(), isNull);
    });

    test('flushRemainder trims and clears buffer', () {
      final b = SentenceBuffer();
      b.pushChunk('  trailing ');
      expect(b.flushRemainder(), 'trailing');
      expect(b.flushRemainder(), isNull);
    });

    test('skips abbreviations before sentence end', () {
      final b = SentenceBuffer();
      expect(b.pushChunk('Mr. Smith went home.'), equals(['Mr. Smith went home.']));
    });
  });
}
