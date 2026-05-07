import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/radio_broadcast_notifier.dart';
import '../../application/llm_settings_notifier.dart';
import '../../../../core/ai/deepseek_client.dart';

/// DeepSeek / 本地模型相关设置。
class SettingsRadioPage extends ConsumerStatefulWidget {
  const SettingsRadioPage({super.key});

  @override
  ConsumerState<SettingsRadioPage> createState() => _SettingsRadioPageState();
}

class _SettingsRadioPageState extends ConsumerState<SettingsRadioPage> {
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _baseUrlCtrl;

  @override
  void initState() {
    super.initState();
    _apiKeyCtrl = TextEditingController();
    _baseUrlCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(llmSettingsProvider.notifier).load();
      final s = ref.read(llmSettingsProvider);
      setState(() {
        _apiKeyCtrl.text = s.apiKey;
        _baseUrlCtrl.text = s.baseUrl;
      });
    });
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _baseUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveApiSettings() async {
    await ref.read(llmSettingsProvider.notifier).setApiKey(_apiKeyCtrl.text);
    await ref.read(llmSettingsProvider.notifier).setBaseUrl(_baseUrlCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存 DeepSeek 密钥与地址')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final llm = ref.watch(llmSettingsProvider);
    final modelAsync = ref.watch(gemmaModelAvailableProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
        children: [
          Text(
            '设置',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('使用 DeepSeek V4（云端 API）'),
            subtitle: const Text('开启并填写有效的 API Key 后，开播将调用 DeepSeek；关闭则使用本地 Gemma / 演示文案。'),
            value: llm.useDeepseek,
            onChanged: (v) => ref.read(llmSettingsProvider.notifier).setUseDeepseek(v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyCtrl,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'DeepSeek API Key',
              hintText: 'sk-…',
              helperText: '密钥保存在本机 SharedPreferences，请勿分享给他人。',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _saveApiSettings,
              icon: const Icon(Icons.save_outlined),
              label: const Text('保存密钥与接口地址'),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: llm.model.isEmpty ? kDeepseekModelFlash : llm.model,
            decoration: const InputDecoration(labelText: 'DeepSeek 模型'),
            items: const [
              DropdownMenuItem(value: kDeepseekModelFlash, child: Text('deepseek-v4-flash')),
              DropdownMenuItem(value: kDeepseekModelPro, child: Text('deepseek-v4-pro')),
            ],
            onChanged: (v) async {
              if (v != null) await ref.read(llmSettingsProvider.notifier).setModel(v);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _baseUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'API Base URL（可选）',
              hintText: kDeepseekDefaultBaseUrl,
              helperText: '一般留空即可；自建网关时再改成你的 HTTPS 地址（末尾勿重复 /v1）。',
            ),
            onSubmitted: (_) async {
              await ref.read(llmSettingsProvider.notifier).setBaseUrl(_baseUrlCtrl.text);
            },
          ),
          const Divider(height: 36),
          Text('本地 Gemma（LiteRT）', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('模型文件'),
            subtitle: modelAsync.when(
              data: (ok) => Text(
                ok ? '已检测到 gemma-4-e2b-it.litertlm，可在关闭云端后本地推理。' : '未检测到模型文件；未启用 DeepSeek 时为演示文案。',
              ),
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
              '使用系统文字转语音（TTS）。若听不到英文，请在系统设置中为 TTS 安装英语语音包。',
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.volume_down_rounded),
            title: const Text('氛围底噪'),
            subtitle: const Text('开播时会播放极低音量循环底噪；暂停播报即停止。'),
          ),
          const Divider(height: 32),
          Text('Night FM · AuraRadio', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            '版本 1.0.0+1 · DeepSeek API（OpenAI 兼容）· 本地 LiteRT / Gemma · Flutter',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
