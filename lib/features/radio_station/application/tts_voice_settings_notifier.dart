import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kLanguage = 'tts_language';
const String _kVoiceJson = 'tts_voice_json';
const String _kSpeechRate = 'tts_speech_rate';

/// Supported UI locales for [FlutterTts.setLanguage].
const List<(String code, String label)> kTtsLanguageChoices = <(String, String)>[
  ('zh-CN', '普通话（简体）'),
  ('zh-TW', '繁体中文（台湾）'),
  ('en-US', 'English (US)'),
];

@immutable
class TtsVoiceSettingsState {
  const TtsVoiceSettingsState({
    required this.loaded,
    this.language = 'zh-CN',
    this.voice,
    this.speechRate = 0.42,
  });

  final bool loaded;

  /// BCP 47 tag passed to [FlutterTts.setLanguage].
  final String language;

  /// Optional engine voice (`name` + `locale`), from [FlutterTts.getVoices].
  final Map<String, String>? voice;

  /// TTS speed (platform-dependent; ~0.35–0.55 works well for narration).
  final double speechRate;

  TtsVoiceSettingsState copyWith({
    bool? loaded,
    String? language,
    Map<String, String>? voice,
    bool clearVoice = false,
    double? speechRate,
  }) {
    return TtsVoiceSettingsState(
      loaded: loaded ?? this.loaded,
      language: language ?? this.language,
      voice: clearVoice ? null : (voice ?? this.voice),
      speechRate: speechRate ?? this.speechRate,
    );
  }
}

final ttsVoiceSettingsProvider =
    NotifierProvider<TtsVoiceSettingsNotifier, TtsVoiceSettingsState>(
        TtsVoiceSettingsNotifier.new);

class TtsVoiceSettingsNotifier extends Notifier<TtsVoiceSettingsState> {
  @override
  TtsVoiceSettingsState build() =>
      const TtsVoiceSettingsState(loaded: false);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    var lang = p.getString(_kLanguage) ?? 'zh-CN';
    if (!kTtsLanguageChoices.any((e) => e.$1 == lang)) {
      lang = 'zh-CN';
    }
    final rate = p.getDouble(_kSpeechRate) ?? 0.42;
    final voice = _decodeVoice(p.getString(_kVoiceJson));
    state = TtsVoiceSettingsState(
      loaded: true,
      language: lang,
      voice: voice,
      speechRate: rate.clamp(0.25, 0.65),
    );
  }

  Future<TtsVoiceSettingsState> ensureLoaded() async {
    if (!state.loaded) await load();
    return state;
  }

  Future<void> setLanguage(String code) async {
    final safe = kTtsLanguageChoices.any((e) => e.$1 == code)
        ? code
        : 'zh-CN';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, safe);
    state = state.copyWith(language: safe, loaded: true);
  }

  Future<void> setVoice(Map<String, String>? voice) async {
    final prefs = await SharedPreferences.getInstance();
    if (voice == null || voice.isEmpty) {
      await prefs.remove(_kVoiceJson);
      state = state.copyWith(clearVoice: true, loaded: true);
      return;
    }
    final normalized = <String, String>{
      for (final e in voice.entries) e.key.trim(): e.value.trim(),
    };
    if (normalized['name'] == null ||
        normalized['name']!.isEmpty ||
        normalized['locale'] == null ||
        normalized['locale']!.isEmpty) {
      await prefs.remove(_kVoiceJson);
      state = state.copyWith(clearVoice: true, loaded: true);
      return;
    }
    await prefs.setString(_kVoiceJson, jsonEncode(normalized));
    state = state.copyWith(voice: normalized, loaded: true);
  }

  Future<void> setSpeechRate(double rate) async {
    final clamped = rate.clamp(0.25, 0.65);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kSpeechRate, clamped);
    state = state.copyWith(speechRate: clamped, loaded: true);
  }

  /// Voices whose locale matches [language] prefix (e.g. `zh-CN` → `zh`).
  Future<List<Map<String, String>>> fetchVoicesForLanguage(
      String language) async {
    final t = FlutterTts();
    try {
      final raw = await t.getVoices;
      final list = _normalizeVoices(raw);
      final prefix = language.trim().toLowerCase().split('-').first;
      list.sort((a, b) {
        final la = a['locale'] ?? '';
        final lb = b['locale'] ?? '';
        final c = la.compareTo(lb);
        if (c != 0) return c;
        return (a['name'] ?? '').compareTo(b['name'] ?? '');
      });
      return list
          .where((v) =>
              (v['locale'] ?? '').toLowerCase().startsWith(prefix) ||
              (v['locale'] ?? '')
                  .toLowerCase()
                  .startsWith(language.toLowerCase()))
          .toList();
    } catch (e, st) {
      debugPrint('fetchVoicesForLanguage: $e\n$st');
      return [];
    }
  }

  static Map<String, String>? _decodeVoice(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final d = jsonDecode(raw);
      if (d is! Map) return null;
      final m = <String, String>{
        for (final e in d.entries) '${e.key}': '${e.value}',
      };
      if ((m['name'] ?? '').isEmpty || (m['locale'] ?? '').isEmpty) {
        return null;
      }
      return m;
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, String>> _normalizeVoices(dynamic raw) {
    if (raw is! List<dynamic>) return [];
    final out = <Map<String, String>>[];
    for (final v in raw) {
      if (v is! Map) continue;
      final name = '${v['name'] ?? v['Name'] ?? ''}'.trim();
      var locale = '${v['locale'] ?? v['Locale'] ?? ''}'.trim();
      if (name.isEmpty || locale.isEmpty) continue;
      locale = locale.replaceAll('_', '-');
      out.add(<String, String>{'name': name, 'locale': locale});
    }
    return out;
  }
}
