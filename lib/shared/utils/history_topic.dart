/// Heuristic: whether a topic is likely to benefit from search-backed factual context.
bool isHistoryTopic(String topic) {
  final t = topic.toLowerCase();
  if (t.isEmpty) return false;
  const keys = <String>[
    'ancient',
    'history',
    'historical',
    'civilization',
    'empire',
    'dynasty',
    'war',
    'century',
    'bc',
    'bce',
    'ad',
    'medieval',
    'roman',
    'egypt',
    'greek',
    'china',
  ];
  return keys.any(t.contains);
}

/// Placeholder for web search / RAG snippets. Return non-null when you have real results.
String? searchContextForTopic(String topic) {
  if (!isHistoryTopic(topic)) return null;
  return null;
}
