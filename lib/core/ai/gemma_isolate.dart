import 'dart:async' show scheduleMicrotask;
import 'dart:isolate';
import 'dart:ui' show RootIsolateToken;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_litert_lm/flutter_litert_lm.dart';

const String kGemmaDelta = 'd';
const String kGemmaDone = 'o';
const String kGemmaError = 'e';

@immutable
class GemmaIsolateStart {
  const GemmaIsolateStart(this.request, this.replyTo);
  final GemmaIsolateRequest request;
  final SendPort replyTo;
}

@immutable
class GemmaIsolateRequest {
  const GemmaIsolateRequest({
    required this.rootToken,
    required this.modelPath,
    required this.userPrompt,
    this.systemInstruction,
    this.extraContext,
  });

  final RootIsolateToken rootToken;
  final String modelPath;
  final String userPrompt;
  final String? systemInstruction;
  final Map<String, Object>? extraContext;
}

@pragma('vm:entry-point')
void gemmaIsolateEntry(GemmaIsolateStart start) {
  scheduleMicrotask(() => _runGemmaInIsolate(start));
}

Future<void> _runGemmaInIsolate(GemmaIsolateStart start) async {
  final send = start.replyTo;
  BackgroundIsolateBinaryMessenger.ensureInitialized(start.request.rootToken);
  LiteLmEngine? engine;
  LiteLmConversation? conversation;
  try {
    engine = await LiteLmEngine.create(
      LiteLmEngineConfig(
        modelPath: start.request.modelPath,
        backend: LiteLmBackend.cpu,
      ),
    );
    final cfg = LiteLmConversationConfig(
      systemInstruction: start.request.systemInstruction,
      samplerConfig: const LiteLmSamplerConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.9,
      ),
    );
    conversation = await engine.createConversation(cfg);
    final stream = conversation.sendMessageStream(
      start.request.userPrompt,
      extraContext: start.request.extraContext,
    );
    await for (final msg in stream) {
      if (msg.text.isNotEmpty) {
        send.send([kGemmaDelta, msg.text]);
      }
    }
    send.send([kGemmaDone]);
  } catch (e, st) {
    debugPrint('Gemma isolate error: $e\n$st');
    send.send([kGemmaError, e.toString()]);
  } finally {
    try {
      await conversation?.dispose();
    } catch (_) {}
    try {
      await engine?.dispose();
    } catch (_) {}
  }
}
