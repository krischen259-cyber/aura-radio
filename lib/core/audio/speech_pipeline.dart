import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Queues sentence-sized lines for [FlutterTts] so lines do not overlap.
class BedtimeTtsPipeline {
  BedtimeTtsPipeline._(this._tts);

  final FlutterTts _tts;
  final Queue<String> _queue = Queue<String>();
  Future<void>? _runner;
  var _disposed = false;

  static const double voiceVolume = 0.95;

  static Future<BedtimeTtsPipeline> create() async {
    final t = FlutterTts();
    final p = BedtimeTtsPipeline._(t);
    await t.setLanguage('en-US');
    await t.setSpeechRate(0.38);
    await t.setVolume(voiceVolume);
    await t.setPitch(0.95);
    return p;
  }

  void enqueue(String sentence) {
    if (_disposed || sentence.trim().isEmpty) return;
    _queue.addLast(sentence.trim());
    _runner ??= _drain();
  }

  Future<void> _drain() async {
    while (_queue.isNotEmpty && !_disposed) {
      final line = _queue.removeFirst();
      try {
        await _tts.speak(line);
      } catch (e) {
        debugPrint('TTS speak error: $e');
      }
    }
    _runner = null;
  }

  Future<void> stop() async {
    _queue.clear();
    await _tts.stop();
  }

  Future<void> dispose() async {
    _disposed = true;
    _queue.clear();
    await _tts.stop();
  }
}
