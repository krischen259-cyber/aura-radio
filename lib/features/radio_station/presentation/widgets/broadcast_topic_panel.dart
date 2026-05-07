import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/llm_settings_notifier.dart';
import '../../application/radio_broadcast_notifier.dart';
import 'topic_chips.dart';

/// 选题并开播（底部表单或探索页共用）。
class BroadcastTopicPanel extends ConsumerStatefulWidget {
  const BroadcastTopicPanel({
    super.key,
    this.initialTopic = '',
    this.stationLabel,
    this.showGrabHandle = true,
  });

  final String initialTopic;
  final String? stationLabel;
  final bool showGrabHandle;

  @override
  ConsumerState<BroadcastTopicPanel> createState() =>
      _BroadcastTopicPanelState();
}

class _BroadcastTopicPanelState extends ConsumerState<BroadcastTopicPanel> {
  late TextEditingController _controller;
  String _preset = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTopic);
    _preset = '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(llmSettingsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _modeBanner(BuildContext context, LlmSettingsState llm, AsyncValue<bool> modelAsync) {
    if (llm.cloudReady) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4EA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC5DFCD)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cloud_done_outlined, color: Colors.teal.shade800, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '已启用 DeepSeek 云端（${llm.model}）。文稿由接口实时生成，需要网络。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          color: const Color(0xFF2F4A38),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return modelAsync.when(
      data: (ok) => ok
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8D9C4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '未检测到本地 Gemma 模型：当前为离线演示文案（除非你在设置里启用 DeepSeek）。可将 gemma-4-e2b-it.litertlm 放入 assets/models/ 后重装。',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                height: 1.35,
                                color: const Color(0xFF5C4A3A),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(radioBroadcastProvider);
    final llm = ref.watch(llmSettingsProvider);
    final modelAsync = ref.watch(gemmaModelAvailableProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showGrabHandle)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          Text(
            '今夜主题',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          _modeBanner(context, llm, modelAsync),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() => _preset = ''),
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(
              hintText: '写下今晚想听的方向，例如：丝路驿站、月球基地、角鱼的灯……',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '英文快捷选题',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          TopicChips(
            selected: _preset,
            onSelect: (t) {
              setState(() {
                _preset = t;
                _controller.text = t;
              });
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: s.phase == RadioPhase.generating ||
                    s.phase == RadioPhase.loading ||
                    s.phase == RadioPhase.speaking
                ? null
                : () async {
                    await ref.read(radioBroadcastProvider.notifier).startBroadcast(
                          _controller.text,
                          stationLabel: widget.stationLabel,
                        );
                    if (context.mounted && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
            child: Text(
              s.phase == RadioPhase.loading || s.phase == RadioPhase.generating
                  ? '正在写入脚本…'
                  : '开始电台播报',
            ),
          ),
          if (s.error != null) ...[
            const SizedBox(height: 12),
            Text(
              s.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
