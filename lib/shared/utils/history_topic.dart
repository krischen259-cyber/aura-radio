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
    '历史',
    '古代',
    '朝代',
    '文明',
    '帝国',
    '世纪',
    '罗马',
    '埃及',
    '希腊',
    '中国',
    '丝绸之路',
    '博物馆',
    '唐',
    '宋',
    '元',
    '明',
    '清',
    '秦',
    '汉',
    '隋',
    '晋',
    '魏',
  ];
  return keys.any(t.contains);
}

/// Placeholder for web search / RAG snippets. Return non-null when you have real results.
String? searchContextForTopic(String topic) {
  if (!isHistoryTopic(topic)) return null;
  return null;
}
