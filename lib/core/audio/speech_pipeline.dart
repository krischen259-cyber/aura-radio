import 'dart:async';
import 'dart:collection';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Queues sentence-sized lines for [FlutterTts] so lines do not overlap.
class BedtimeTtsPipeline {
  BedtimeTtsPipeline._(this._tts);

  final FlutterTts _tts;
  final Queue<String> _queue = Queue<String>();
  Future<void>? _runner;
  var _disposed = false;

  static const double defaultVoiceVolume = 0.95;

  /// [language] should match content (e.g. `zh-CN` for Chinese scripts).
  static Future<BedtimeTtsPipeline> create({
    String language = 'zh-CN',
    Map<String, String>? voice,
    double speechRate = 0.42,
    double pitch = 1.0,
    double volume = defaultVoiceVolume,
  }) async {
    final t = FlutterTts();
    final p = BedtimeTtsPipeline._(t);
    await t.awaitSpeakCompletion(true);
    if (!kIsWeb && Platform.isAndroid) {
      await t.setQueueMode(1);
    }
    t.setErrorHandler((m) => debugPrint('TTS platform error: $m'));
    await t.setLanguage(language);
    if (voice != null && voice.isNotEmpty) {
      try {
        await t.setVoice(Map<String, String>.from(voice));
      } catch (e) {
        debugPrint('TTS setVoice skipped: $e');
      }
    }
    await t.setSpeechRate(speechRate);
    await t.setVolume(volume.clamp(0.0, 1.0));
    await t.setPitch(pitch.clamp(0.5, 2.0));
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
