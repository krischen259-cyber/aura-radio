import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/deepseek_client.dart';
import '../../../core/ai/gemma_service.dart';
import '../../../core/audio/atmosphere_player.dart';
import '../../../core/audio/radio_audio_session.dart';
import '../../../core/audio/speech_pipeline.dart';
import '../../../shared/utils/history_topic.dart';
import '../../../shared/utils/sentence_buffer.dart';
import 'llm_settings_notifier.dart';
import 'tts_voice_settings_notifier.dart';

enum RadioPhase { idle, loading, generating, speaking, error }

class RadioUiState {
  const RadioUiState({
    required this.phase,
    this.error,
    this.accumulatedText = '',
    this.activeTopic,
    this.stationLabel,
  });

  final RadioPhase phase;
  final String? error;
  final String accumulatedText;

  /// Last / current broadcast topic (user-facing).
  final String? activeTopic;

  /// e.g. 晚安博物馆 — shown on the player chrome.
  final String? stationLabel;

  RadioUiState copyWith({
    RadioPhase? phase,
    String? error,
    bool clearError = false,
    String? accumulatedText,
    String? activeTopic,
    String? stationLabel,
    bool clearStation = false,
  }) {
    return RadioUiState(
      phase: phase ?? this.phase,
      error: clearError ? null : (error ?? this.error),
      accumulatedText: accumulatedText ?? this.accumulatedText,
      activeTopic: activeTopic ?? this.activeTopic,
      stationLabel: clearStation ? null : (stationLabel ?? this.stationLabel),
    );
  }
}

final gemmaServiceProvider = Provider<GemmaService>((ref) {
  final s = GemmaService();
  ref.onDispose(s.dispose);
  return s;
});

/// Whether `gemma-4-e2b-it.litertlm` is available (support dir or bundled asset).
final gemmaModelAvailableProvider = FutureProvider<bool>((ref) async {
  final path = await ref.watch(gemmaServiceProvider).ensureModelFile();
  return path != null;
});

final radioBroadcastProvider =
    NotifierProvider<RadioBroadcastNotifier, RadioUiState>(RadioBroadcastNotifier.new);

class RadioBroadcastNotifier extends Notifier<RadioUiState> {
  StreamSubscription<String>? _llmSub;
  AtmospherePlayer? _atmo;
  BedtimeTtsPipeline? _tts;

  @override
  RadioUiState build() {
    return const RadioUiState(phase: RadioPhase.idle);
  }

  Future<void> startBroadcast(
    String rawTopic, {
    String? stationLabel,
  }) async {
    final topic = rawTopic.trim();
    if (topic.isEmpty) {
      state = RadioUiState(
        phase: RadioPhase.error,
        error: '请输入或选择一个主题。',
        activeTopic: state.activeTopic,
        stationLabel: state.stationLabel,
      );
      return;
    }

    await _releaseAudio();
    state = RadioUiState(
      phase: RadioPhase.loading,
      accumulatedText: '',
      activeTopic: topic,
      stationLabel: stationLabel ?? state.stationLabel,
    );

    try {
      await configureRadioAudioSession();
      _atmo = AtmospherePlayer();
      await _atmo!.setVolume(AtmospherePlayer.defaultVolume);
      await _atmo!.init();
      unawaited(_atmo!.play());
      await ref.read(ttsVoiceSettingsProvider.notifier).ensureLoaded();
      final ttsCfg = ref.read(ttsVoiceSettingsProvider);
      _tts = await BedtimeTtsPipeline.create(
        language: ttsCfg.language,
        voice: ttsCfg.voice,
        speechRate: ttsCfg.speechRate,
      );
    } catch (e) {
      state = RadioUiState(
        phase: RadioPhase.error,
        error: '音频初始化失败：$e',
        activeTopic: state.activeTopic,
        stationLabel: state.stationLabel,
      );
      return;
    }

    state = RadioUiState(
      phase: RadioPhase.generating,
      accumulatedText: '',
      activeTopic: topic,
      stationLabel: stationLabel ?? state.stationLabel,
    );

    final context = isHistoryTopic(topic) ? searchContextForTopic(topic) : null;
    await ref.read(llmSettingsProvider.notifier).ensureLoaded();
    final cfg = ref.read(llmSettingsProvider);

    late final Stream<String> scriptStream;
    if (cfg.cloudReady) {
      final base =
          cfg.baseUrl.trim().isEmpty ? kDeepseekDefaultBaseUrl : cfg.baseUrl.trim();
      scriptStream = DeepseekRadioClient(
        apiKey: cfg.apiKey.trim(),
        baseUrl: base,
        model: cfg.model.trim().isEmpty ? kDeepseekModelFlash : cfg.model.trim(),
      ).streamRadioScript(topic, context: context);
    } else {
      scriptStream =
          ref.read(gemmaServiceProvider).generateRadioScript(topic, context: context);
    }

    final buffer = SentenceBuffer();
    final acc = StringBuffer();

    _llmSub = scriptStream.listen(
      (delta) {
        acc.write(delta);
        for (final line in buffer.pushChunk(delta)) {
          state = state.copyWith(
            phase: RadioPhase.speaking,
            accumulatedText: acc.toString(),
          );
          _tts?.enqueue(line);
        }
      },
      onError: (e) async {
        state = RadioUiState(
          phase: RadioPhase.error,
          error: '$e',
          activeTopic: topic,
          stationLabel: stationLabel ?? state.stationLabel,
        );
        await _releaseAudio();
      },
      onDone: () {
        final tail = buffer.flushRemainder();
        if (tail != null && tail.isNotEmpty) {
          _tts?.enqueue(tail);
        }
        final fullText = acc.toString();
        if (fullText.trim().isEmpty) {
          unawaited(_releaseAudio());
          state = RadioUiState(
            phase: RadioPhase.error,
            error:
                '未生成文稿（内容为空）。请检查网络与 DeepSeek API Key，或本地 Gemma 模型。',
            activeTopic: topic,
            stationLabel: stationLabel ?? state.stationLabel,
          );
          return;
        }
        state = state.copyWith(
          phase: RadioPhase.speaking,
          accumulatedText: fullText,
          activeTopic: topic,
          stationLabel: stationLabel ?? state.stationLabel,
        );
        Future<void>.delayed(const Duration(seconds: 1), () {
          if (state.phase == RadioPhase.speaking) {
            state = state.copyWith(phase: RadioPhase.idle);
          }
        });
      },
      cancelOnError: true,
    );
  }

  /// Stops LLM, ambience, and the speech queue.
  Future<void> stopBroadcast() async {
    await _llmSub?.cancel();
    _llmSub = null;
    await _releaseAudio();
    if (state.phase != RadioPhase.error) {
      state = RadioUiState(
        phase: RadioPhase.idle,
        accumulatedText: '',
        activeTopic: state.activeTopic,
        stationLabel: state.stationLabel,
      );
    }
  }

  Future<void> _releaseAudio() async {
    await _llmSub?.cancel();
    _llmSub = null;
    try {
      await _tts?.stop();
      await _tts?.dispose();
    } catch (_) {}
    _tts = null;
    try {
      await _atmo?.stop();
      await _atmo?.dispose();
    } catch (_) {}
    _atmo = null;
  }

  /// Clears TTS queue only (LLM stream / 底噪 unchanged).
  Future<void> stopSpeechOnly() async {
    await _tts?.stop();
  }

  /// Re-reads current transcript with saved voice settings (use after 整场 idle or to retry).
  Future<void> replayAccumulatedSpeech() async {
    final text = state.accumulatedText.trim();
    if (text.isEmpty) return;
    try {
      await configureRadioAudioSession();
      await ref.read(ttsVoiceSettingsProvider.notifier).ensureLoaded();
      final ttsCfg = ref.read(ttsVoiceSettingsProvider);
      _tts ??= await BedtimeTtsPipeline.create(
        language: ttsCfg.language,
        voice: ttsCfg.voice,
        speechRate: ttsCfg.speechRate,
      );
      await _tts!.stop();
      for (final line in SentenceBuffer.sentencesFromFullText(text)) {
        _tts!.enqueue(line);
      }
    } catch (e, st) {
      debugPrint('replayAccumulatedSpeech: $e\n$st');
    }
  }
}
