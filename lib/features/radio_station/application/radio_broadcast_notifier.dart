import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/gemma_service.dart';
import '../../../core/audio/atmosphere_player.dart';
import '../../../core/audio/radio_audio_session.dart';
import '../../../core/audio/speech_pipeline.dart';
import '../../../shared/utils/history_topic.dart';
import '../../../shared/utils/sentence_buffer.dart';

enum RadioPhase { idle, loading, generating, speaking, error }

class RadioUiState {
  const RadioUiState({
    required this.phase,
    this.error,
    this.accumulatedText = '',
  });

  final RadioPhase phase;
  final String? error;
  final String accumulatedText;

  RadioUiState copyWith({
    RadioPhase? phase,
    String? error,
    bool clearError = false,
    String? accumulatedText,
  }) {
    return RadioUiState(
      phase: phase ?? this.phase,
      error: clearError ? null : (error ?? this.error),
      accumulatedText: accumulatedText ?? this.accumulatedText,
    );
  }
}

final gemmaServiceProvider = Provider<GemmaService>((ref) {
  final s = GemmaService();
  ref.onDispose(s.dispose);
  return s;
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

  Future<void> startBroadcast(String rawTopic) async {
    final topic = rawTopic.trim();
    if (topic.isEmpty) {
      state = const RadioUiState(
        phase: RadioPhase.error,
        error: 'Please enter a topic.',
      );
      return;
    }

    await _releaseAudio();
    state = const RadioUiState(phase: RadioPhase.loading, accumulatedText: '');

    try {
      await configureRadioAudioSession();
      _atmo = AtmospherePlayer();
      await _atmo!.setVolume(AtmospherePlayer.defaultVolume);
      await _atmo!.init();
      unawaited(_atmo!.play());
      _tts = await BedtimeTtsPipeline.create();
    } catch (e) {
      state = RadioUiState(phase: RadioPhase.error, error: 'Audio init failed: $e');
      return;
    }

    state = const RadioUiState(phase: RadioPhase.generating, accumulatedText: '');

    final context = isHistoryTopic(topic) ? searchContextForTopic(topic) : null;
    final gemma = ref.read(gemmaServiceProvider);
    final buffer = SentenceBuffer();
    final acc = StringBuffer();

    final stream = gemma.generateRadioScript(topic, context: context);
    _llmSub = stream.listen(
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
        state = RadioUiState(phase: RadioPhase.error, error: '$e');
        await _releaseAudio();
      },
      onDone: () {
        final tail = buffer.flushRemainder();
        if (tail != null && tail.isNotEmpty) {
          _tts?.enqueue(tail);
        }
        state = state.copyWith(
          phase: RadioPhase.speaking,
          accumulatedText: acc.toString(),
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
      state = const RadioUiState(phase: RadioPhase.idle, accumulatedText: '');
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
}
