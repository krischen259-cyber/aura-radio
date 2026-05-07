import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_litert_lm/flutter_litert_lm.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'gemma_isolate.dart'
    show
        GemmaIsolateRequest,
        GemmaIsolateStart,
        gemmaIsolateEntry,
        kGemmaDelta,
        kGemmaDone,
        kGemmaError;
import 'radio_prompts.dart';
import '../../shared/utils/history_topic.dart';

/// Loads Gemma (LiteRT-LM `.litertlm`) and streams bedtime radio copy.
class GemmaService {
  GemmaService();

  static const String kModelFileName = 'gemma-4-e2b-it.litertlm';
  static const String kModelAssetKey = 'assets/models/gemma-4-e2b-it.litertlm';

  /// Cached engine on the **main** isolate (used when the worker isolate is unavailable).
  LiteLmEngine? _mainEngine;
  String? _engineModelPath;

  /// Resolves a readable `.litertlm` path: app support dir first, then small asset copy.
  Future<String?> ensureModelFile() async {
    final dir = await getApplicationSupportDirectory();
    final target = File(p.join(dir.path, kModelFileName));
    if (await target.exists() && await target.length() > 0) {
      return target.path;
    }
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final map = json.decode(manifest) as Map<String, dynamic>;
      if (!map.containsKey(kModelAssetKey)) {
        if (kDebugMode) {
          debugPrint(
              'AuraRadio: no $kModelFileName in support dir; asset not in bundle.');
        }
        return null;
      }
      if (kDebugMode) {
        debugPrint(
          'AuraRadio: copying $kModelAssetKey — large models may OOM; prefer placing the file in app support dir.',
        );
      }
      final data = await rootBundle.load(kModelAssetKey);
      await target.writeAsBytes(data.buffer.asUint8List());
      return target.path;
    } catch (e) {
      debugPrint('ensureModelFile: $e');
      return null;
    }
  }

  /// Optional extra RAG / search text for the LiteRT-LM `extraContext` map.
  Map<String, Object>? _extraForLiteRt(String topic, String? context) {
    if (context == null || context.isEmpty) return null;
    if (!isHistoryTopic(topic)) return null;
    return <String, Object>{
      'retrieval': context,
      'source': 'search_simulation',
    };
  }

  /// Streams **delta** text (same as the underlying LiteRT token events).
  Stream<String> generateRadioScript(
    String topic, {
    String? context,
    bool useBackgroundIsolate = true,
  }) async* {
    final path = await ensureModelFile();
    const system = kRadioSystemInstruction;
    final user = buildRadioUserPrompt(topic, context);
    final extra = _extraForLiteRt(topic, context);

    if (path == null) {
      yield* _mockLlmStream(topic);
      return;
    }

    if (useBackgroundIsolate) {
      final token = RootIsolateToken.instance;
      if (token != null) {
        try {
          yield* _streamFromBackgroundIsolate(
            modelPath: path,
            systemInstruction: system,
            userPrompt: user,
            extraContext: extra,
            rootToken: token,
          );
          return;
        } catch (e, st) {
          debugPrint('Background isolate path failed, using main: $e\n$st');
        }
      }
    }

    yield* _streamFromMainEngine(
      modelPath: path,
      systemInstruction: system,
      userPrompt: user,
      extraContext: extra,
    );
  }

  Stream<String> _streamFromBackgroundIsolate({
    required String modelPath,
    required String systemInstruction,
    required String userPrompt,
    required Map<String, Object>? extraContext,
    required RootIsolateToken rootToken,
  }) async* {
    final receivePort = ReceivePort();
    final request = GemmaIsolateRequest(
      rootToken: rootToken,
      modelPath: modelPath,
      userPrompt: userPrompt,
      systemInstruction: systemInstruction,
      extraContext: extraContext,
    );
    try {
      await Isolate.spawn(
        gemmaIsolateEntry,
        GemmaIsolateStart(request, receivePort.sendPort),
        errorsAreFatal: false,
      );
      var done = false;
      await for (final message
          in receivePort.timeout(const Duration(minutes: 20))) {
        if (message is! List) continue;
        if (message.isEmpty) continue;
        final tag = message[0];
        if (tag == kGemmaDelta && message.length >= 2) {
          yield message[1] as String;
        } else if (tag == kGemmaDone) {
          done = true;
          break;
        } else if (tag == kGemmaError && message.length >= 2) {
          throw StateError('LiteRT isolate: ${message[1]}');
        }
      }
      if (!done) {
        throw StateError('LLM stream ended without completion signal.');
      }
    } on TimeoutException {
      throw StateError('LLM stream timed out.');
    } finally {
      receivePort.close();
    }
  }

  Future<LiteLmEngine> _getOrCreateMainEngine(String modelPath) async {
    if (_mainEngine != null && _engineModelPath == modelPath) {
      return _mainEngine!;
    }
    await _mainEngine?.dispose();
    _mainEngine = null;
    _engineModelPath = null;
    final eng = await LiteLmEngine.create(
      LiteLmEngineConfig(modelPath: modelPath, backend: LiteLmBackend.cpu),
    );
    _mainEngine = eng;
    _engineModelPath = modelPath;
    return eng;
  }

  Stream<String> _streamFromMainEngine({
    required String modelPath,
    required String systemInstruction,
    required String userPrompt,
    required Map<String, Object>? extraContext,
  }) async* {
    final eng = await _getOrCreateMainEngine(modelPath);
    final conv = await eng.createConversation(
      LiteLmConversationConfig(
        systemInstruction: systemInstruction,
        samplerConfig: const LiteLmSamplerConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.9,
        ),
      ),
    );
    try {
      final stream = conv.sendMessageStream(
        userPrompt,
        extraContext: extraContext,
      );
      await for (final msg in stream) {
        if (msg.text.isNotEmpty) yield msg.text;
      }
    } finally {
      await conv.dispose();
    }
  }

  Stream<String> _mockLlmStream(String topic) async* {
    const line =
        'This is a gentle offline preview. Place gemma-4-e2b-it.litertlm in app support, '
        'or add it as a bundled asset, then restart. ';
    for (var i = 0; i < line.length; i++) {
      yield line[i];
      await Future<void>.delayed(const Duration(milliseconds: 4));
    }
    final outro =
        'We float through "$topic" tonight — soft, slow, and unhurried. The night holds you. Rest well.';
    for (var i = 0; i < outro.length; i++) {
      yield outro[i];
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  /// Dispose a cached main-isolate engine (not used by a running worker isolate).
  Future<void> dispose() async {
    try {
      await _mainEngine?.dispose();
    } catch (_) {}
    _mainEngine = null;
    _engineModelPath = null;
  }
}
