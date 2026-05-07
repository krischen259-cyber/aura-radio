/// 与 Stitch 横向电台 Chip 对应：中文名 + 送给本地模型的提示主题。
class NightFmStation {
  const NightFmStation({
    required this.id,
    required this.nameZh,
    required this.topicPrompt,
    required this.subtitleZh,
    required this.fmBand,
  });

  final String id;
  final String nameZh;
  final String topicPrompt;
  final String subtitleZh;
  final String fmBand;

  static const List<NightFmStation> all = [
    NightFmStation(
      id: 'museum',
      nameZh: '晚安博物馆',
      topicPrompt: '以博物馆闭馆后的静谧夜色为背景，讲述古代文明与器物背后的温柔轶事，语气舒缓适合入睡。',
      subtitleZh: '文明絮语 · 慢叙事',
      fmBand: 'FM 97.3',
    ),
    NightFmStation(
      id: 'deep_space',
      nameZh: '深空',
      topicPrompt: '深空探测器、星云与光的微弱回响，用极简科普与诗意比喻描绘宇宙之静。',
      subtitleZh: '轨道轻声 · 星际留白',
      fmBand: 'FM 102.1',
    ),
    NightFmStation(
      id: 'ocean',
      nameZh: '海语',
      topicPrompt: '深海生物发光、洋流与白噪音般的潮汐，营造水下摇篮般的叙述。',
      subtitleZh: '潮汐冥想 · 深蓝呼吸',
      fmBand: 'FM 88.6',
    ),
    NightFmStation(
      id: 'poetry',
      nameZh: '诗集',
      topicPrompt: '古典与现代散文诗片段的轻声诵读主题，意象偏月夜、灯火与远行。',
      subtitleZh: '字句如雾 · 低声诵读',
      fmBand: 'FM 91.0',
    ),
    NightFmStation(
      id: 'forest',
      nameZh: '森林',
      topicPrompt: '雨林晨雾、苔藓与远处鸟鸣的意象，带领听者走入透气感极强的林间小径。',
      subtitleZh: '绿意庇护 · 林间回响',
      fmBand: 'FM 94.5',
    ),
  ];

  static NightFmStation? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}
