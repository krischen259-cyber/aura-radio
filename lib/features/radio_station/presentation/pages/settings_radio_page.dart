import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/radio_broadcast_notifier.dart';

/// 模型状态与简要说明。
class SettingsRadioPage extends ConsumerWidget {
  const SettingsRadioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelAsync = ref.watch(gemmaModelAvailableProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
        children: [
          Text(
            '设置',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('本地 Gemma 模型'),
            subtitle: modelAsync.when(
              data: (ok) => Text(ok
                  ? '已检测到 gemma-4-e2b-it.litertlm，可进行真实生成。'
                  : '未检测到模型，当前为演示文案模式。'),
              loading: () => const Text('正在检查…'),
              error: (e, _) => Text('检查失败：$e'),
            ),
          ),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.record_voice_over_outlined),
            title: const Text('朗读引擎'),
            subtitle: const Text(
              '本应用使用系统文字转语音（TTS）。若听不到英文声音，请在系统设置中为 TTS 安装英语语音包。',
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.volume_down_rounded),
            title: const Text('氛围底噪'),
            subtitle: const Text('开播时会播放极低音量循环底噪，可与朗读同时聆听；暂停播报即停止。'),
          ),
          const Divider(height: 32),
          Text(
            'Night FM · AuraRadio',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            '版本 1.0.0+1 · 本地 LiteRT / Gemma 推理 · Flutter',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
