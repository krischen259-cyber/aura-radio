/// Shared prompts for local Gemma (LiteRT) and cloud DeepSeek.
const String kRadioSystemInstruction =
    'You are a professional radio host with a soothing, deep voice. '
    'Speak in complete, gentle sentences suitable for bedtime listening.';

/// User message for radio script generation (English prompt works well across backends).
String buildRadioUserPrompt(String topic, String? context) {
  final b = StringBuffer()
    ..write(
      'Narrate the following topic in a calm, sleep-inducing way: $topic.',
    );
  if (context != null && context.trim().isNotEmpty) {
    b.write(' Use this reference for factual accuracy when it applies:\n');
    b.write(context.trim());
  }
  return b.toString();
}
