import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'radio_prompts.dart';

/// Default DeepSeek OpenAI-compatible endpoint (HTTPS).
const String kDeepseekDefaultBaseUrl = 'https://api.deepseek.com';

/// V4 line — adjust if DeepSeek renames models.
const String kDeepseekModelFlash = 'deepseek-v4-flash';
const String kDeepseekModelPro = 'deepseek-v4-pro';

/// Streams assistant **content** deltas from `POST /v1/chat/completions` with `stream: true`.
/// Parses SSE lines (`data: {...}` / `[DONE]`).
class DeepseekRadioClient {
  DeepseekRadioClient({
    required this.apiKey,
    this.baseUrl = kDeepseekDefaultBaseUrl,
    required this.model,
  });

  final String apiKey;
  final String baseUrl;
  final String model;

  Stream<String> streamRadioScript(
    String topic, {
    String? context,
  }) async* {
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/v1/chat/completions');
    final body = jsonEncode(<String, dynamic>{
      'model': model,
      'messages': <Map<String, String>>[
        {'role': 'system', 'content': kRadioSystemInstruction},
        {'role': 'user', 'content': buildRadioUserPrompt(topic, context)},
      ],
      'stream': true,
      'temperature': 0.7,
    });

    final client = http.Client();
    try {
      final request = http.Request('POST', uri)
        ..headers.addAll(<String, String>{
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        })
        ..body = body;

      final streamed = await client.send(request).timeout(const Duration(seconds: 45));
      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        final errBody = await streamed.stream.bytesToString();
        throw DeepseekApiException(
          'HTTP ${streamed.statusCode}',
          body: errBody,
        );
      }

      var carry = '';
      await for (final chunk in streamed.stream.transform(utf8.decoder)) {
        carry += chunk;
        var boundary = carry.indexOf('\n');
        while (boundary != -1) {
          var line = carry.substring(0, boundary).trimRight();
          carry = carry.substring(boundary + 1);
          boundary = carry.indexOf('\n');

          line = line.trim();
          if (line.isEmpty) continue;
          if (!line.startsWith('data:')) continue;
          final payload = line.substring(5).trim();
          if (payload == '[DONE]') return;

          Map<String, dynamic> obj;
          try {
            obj = json.decode(payload) as Map<String, dynamic>;
          } catch (e) {
            if (kDebugMode) debugPrint('DeepSeek SSE skip parse: $e → $payload');
            continue;
          }

          final delta = _extractDeltaText(obj);
          if (delta != null && delta.isNotEmpty) {
            yield delta;
          }
        }
      }
    } on TimeoutException {
      throw DeepseekApiException('连接超时', body: null);
    } finally {
      client.close();
    }
  }

  /// OpenAI-style chunk: `choices[0].delta.content` (string or null).
  static String? _extractDeltaText(Map<String, dynamic> obj) {
    final choices = obj['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map<String, dynamic>) return null;
    final delta = first['delta'];
    if (delta is! Map<String, dynamic>) return null;
    final content = delta['content'];
    if (content is String && content.isNotEmpty) return content;
    return null;
  }
}

class DeepseekApiException implements Exception {
  DeepseekApiException(this.message, {this.body});

  final String message;
  final String? body;

  @override
  String toString() {
    if (body == null || body!.isEmpty) return 'DeepSeek API: $message';
    final short = body!.length > 280 ? '${body!.substring(0, 280)}…' : body!;
    return 'DeepSeek API: $message — $short';
  }
}
