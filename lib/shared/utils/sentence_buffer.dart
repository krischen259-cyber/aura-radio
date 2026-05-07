/// Buffers token/stream chunks and yields complete sentences for TTS.
class SentenceBuffer {
  final StringBuffer _buf = StringBuffer();

  /// One-shot split for replay / offline queues (handles CN `。！？` and Latin `.!?`).
  static List<String> sentencesFromFullText(String text) {
    final b = SentenceBuffer();
    final out = <String>[...b.pushChunk(text)];
    final tail = b.flushRemainder();
    if (tail != null && tail.isNotEmpty) out.add(tail);
    return out;
  }

  /// Pushes a new text chunk. Returns 0+ completed sentences to speak.
  List<String> pushChunk(String chunk) {
    if (chunk.isEmpty) return const [];
    _buf.write(chunk);
    return _flushCompleteSentences();
  }

  /// Call when the model stream is done: speak any remaining text.
  String? flushRemainder() {
    final t = _buf.toString();
    _buf.clear();
    final s = t.trim();
    if (s.isEmpty) return null;
    return s;
  }

  List<String> _flushCompleteSentences() {
    var text = _buf.toString();
    final out = <String>[];
    while (text.isNotEmpty) {
      final i = _nextSentenceEnd(text);
      if (i == null) break;
      final sentence = text.substring(0, i + 1).trim();
      if (sentence.isNotEmpty) out.add(sentence);
      text = text.substring(i + 1);
    }
    _buf
      ..clear()
      ..write(text);
    return out;
  }

  /// Latin `.!?` (with light spacing rules) and CJK `。！？`.
  int? _nextSentenceEnd(String s) {
    for (var p = 0; p < s.length; p++) {
      final c = s[p];
      if (c == '。' || c == '！' || c == '？') {
        return p;
      }
      if (c != '.' && c != '!' && c != '?') continue;
      if (c == '.' && _isAbbrevDot(s, p)) continue;
      if (p + 1 < s.length) {
        final n = s[p + 1];
        if (n == ' ' ||
            n == '\n' ||
            n == '\t' ||
            n == '”' ||
            n == '"' ||
            n == '』' ||
            n == '」') {
          return p;
        }
      } else {
        return p; // end of current buffer, treat as end of sentence
      }
    }
    return null;
  }

  bool _isAbbrevDot(String s, int p) {
    if (p < 1 || s[p] != '.') return false;
    final start = (p - 2).clamp(0, s.length);
    final slice = s.substring(start, p + 1).toLowerCase();
    return slice == 'mr.' || slice == 'dr.' || slice == 'ms.' || slice == 'st.';
  }
}
