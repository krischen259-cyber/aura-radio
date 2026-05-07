import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/ai/deepseek_client.dart';

const String _kUseDeepseek = 'use_deepseek';
const String _kApiKey = 'deepseek_api_key';
const String _kModel = 'deepseek_model';
const String _kBaseUrl = 'deepseek_base_url';

@immutable
class LlmSettingsState {
  const LlmSettingsState({
    required this.loaded,
    this.useDeepseek = false,
    this.apiKey = '',
    this.model = kDeepseekModelFlash,
    this.baseUrl = '',
  });

  final bool loaded;
  final bool useDeepseek;
  final String apiKey;
  final String model;

  /// Empty → use [kDeepseekDefaultBaseUrl].
  final String baseUrl;

  LlmSettingsState copyWith({
    bool? loaded,
    bool? useDeepseek,
    String? apiKey,
    String? model,
    String? baseUrl,
  }) {
    return LlmSettingsState(
      loaded: loaded ?? this.loaded,
      useDeepseek: useDeepseek ?? this.useDeepseek,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }

  bool get cloudReady => useDeepseek && apiKey.trim().isNotEmpty;
}

final llmSettingsProvider =
    NotifierProvider<LlmSettingsNotifier, LlmSettingsState>(
        LlmSettingsNotifier.new);

class LlmSettingsNotifier extends Notifier<LlmSettingsState> {
  @override
  LlmSettingsState build() => const LlmSettingsState(loaded: false);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    var model = p.getString(_kModel) ?? kDeepseekModelFlash;
    if (model != kDeepseekModelFlash && model != kDeepseekModelPro) {
      model = kDeepseekModelFlash;
      await p.setString(_kModel, model);
    }
    state = LlmSettingsState(
      loaded: true,
      useDeepseek: p.getBool(_kUseDeepseek) ?? false,
      apiKey: p.getString(_kApiKey) ?? '',
      model: model,
      baseUrl: p.getString(_kBaseUrl) ?? '',
    );
  }

  /// Ensures prefs were read at least once.
  Future<LlmSettingsState> ensureLoaded() async {
    if (!state.loaded) await load();
    return state;
  }

  Future<void> setUseDeepseek(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kUseDeepseek, v);
    state = state.copyWith(useDeepseek: v, loaded: true);
  }

  Future<void> setApiKey(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kApiKey, v.trim());
    state = state.copyWith(apiKey: v.trim(), loaded: true);
  }

  Future<void> setModel(String v) async {
    final safe =
        v == kDeepseekModelPro ? kDeepseekModelPro : kDeepseekModelFlash;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kModel, safe);
    state = state.copyWith(model: safe, loaded: true);
  }

  Future<void> setBaseUrl(String v) async {
    final trimmed = v.trim();
    final p = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await p.remove(_kBaseUrl);
      state = state.copyWith(baseUrl: '', loaded: true);
    } else {
      await p.setString(_kBaseUrl, trimmed);
      state = state.copyWith(baseUrl: trimmed, loaded: true);
    }
  }
}
