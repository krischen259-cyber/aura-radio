import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/llm_settings_notifier.dart';
import '../../application/radio_broadcast_notifier.dart';
import '../../application/tts_voice_settings_notifier.dart';
import '../../../../core/ai/deepseek_client.dart';

/// DeepSeek / 本地模型相关设置。
/// 必须使用 [Scaffold]（或上层 [Material]）：[SwitchListTile] / [DropdownButtonFormField]
/// 在 [IndexedStack] 里没有 Material 祖先时，在部分设备上会整页无法绘制（表现为大面积空白）。
class SettingsRadioPage extends ConsumerStatefulWidget {
  const SettingsRadioPage({super.key});

  @override
  ConsumerState<SettingsRadioPage> createState() => _SettingsRadioPageState();
}

class _SettingsRadioPageState extends ConsumerState<SettingsRadioPage> {
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _baseUrlCtrl;
  List<Map<String, String>> _ttsVoices = [];
  var _ttsVoicesLoading = false;

  @override
  void initState() {
    super.initState();
    _apiKeyCtrl = TextEditingController();
    _baseUrlCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(llmSettingsProvider.notifier).load();
      await ref.read(ttsVoiceSettingsProvider.notifier).load();
      final s = ref.read(llmSettingsProvider);
      if (!mounted) return;
      setState(() {
        _apiKeyCtrl.text = s.apiKey;
        _baseUrlCtrl.text = s.baseUrl;
      });
      await _refreshTtsVoices();
    });
  }

  Future<void> _refreshTtsVoices() async {
    final lang = ref.read(ttsVoiceSettingsProvider).language;
    setState(() => _ttsVoicesLoading = true);
    final list =
        await ref.read(ttsVoiceSettingsProvider.notifier).fetchVoicesForLanguage(lang);
    if (!mounted) return;
    setState(() {
      _ttsVoices = list;
      _ttsVoicesLoading = false;
    });
  }

  int _ttsVoiceDropdownValue(TtsVoiceSettingsState tts) {
    final v = tts.voice;
    if (v == null) return -1;
    for (var i = 0; i < _ttsVoices.length; i++) {
      if (_ttsVoices[i]['name'] == v['name'] &&
          _ttsVoices[i]['locale'] == v['locale']) {
        return i;
      }
    }
    return -1;
  }

  String _ttsSpeechRateLabel(double r) => '×${r.toStringAsFixed(2)}';

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
    final scheme = Theme.of(context).colorScheme;
    final llm = ref.watch(llmSettingsProvider);
    final tts = ref.watch(ttsVoiceSettingsProvider);
    final modelAsync = ref.watch(gemmaModelAvailableProvider);

    final dropdownModel =
        llm.model == kDeepseekModelPro ? kDeepseekModelPro : kDeepseekModelFlash;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
          children: [
            Text(
              '设置',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('使用 DeepSeek V4（云端 API）'),
              subtitle: const Text(
                '开启并填写有效的 API Key 后，开播将调用 DeepSeek；关闭则使用本地 Gemma / 演示文案。',
              ),
              value: llm.useDeepseek,
              onChanged: (v) => ref.read(llmSettingsProvider.notifier).setUseDeepseek(v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyCtrl,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              style: TextStyle(color: scheme.onSurface),
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
              value: dropdownModel,
              decoration: const InputDecoration(labelText: 'DeepSeek 模型'),
              items: const [
                DropdownMenuItem(
                  value: kDeepseekModelFlash,
                  child: Text('deepseek-v4-flash'),
                ),
                DropdownMenuItem(
                  value: kDeepseekModelPro,
                  child: Text('deepseek-v4-pro'),
                ),
              ],
              onChanged: (v) async {
                if (v != null) {
                  await ref.read(llmSettingsProvider.notifier).setModel(v);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _baseUrlCtrl,
              style: TextStyle(color: scheme.onSurface),
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
            Text(
              '本地 Gemma（LiteRT）',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('模型文件'),
              subtitle: modelAsync.when(
                data: (ok) => Text(
                  ok
                      ? '已检测到 gemma-4-e2b-it.litertlm，可在关闭云端后本地推理。'
                      : '未检测到模型文件；未启用 DeepSeek 时为演示文案。',
                ),
                loading: () => const Text('正在检查…'),
                error: (e, _) => Text('检查失败：$e'),
              ),
            ),
            const Divider(height: 32),
            Text(
              '朗读语音（系统 TTS）',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              '中文电台文稿默认按所选语言朗读。若无声音，请在系统「无障碍 / 文字转语音」中安装中文语音包。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: tts.loaded ? tts.language : kTtsLanguageChoices.first.$1, // ignore: deprecated_member_use
              decoration: const InputDecoration(labelText: '朗读语言'),
              items: [
                for (final e in kTtsLanguageChoices)
                  DropdownMenuItem(value: e.$1, child: Text(e.$2)),
              ],
              onChanged: !tts.loaded
                  ? null
                  : (v) async {
                      if (v == null) return;
                      await ref.read(ttsVoiceSettingsProvider.notifier).setLanguage(v);
                      await ref.read(ttsVoiceSettingsProvider.notifier).setVoice(null);
                      await _refreshTtsVoices();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已切换朗读语言，如需固定音色请重新选择')),
                      );
                    },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _ttsVoicesLoading ? null : _refreshTtsVoices,
                icon: _ttsVoicesLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(_ttsVoicesLoading ? '读取音色列表…' : '刷新本机音色列表'),
              ),
            ),
            DropdownButtonFormField<int>(
              value: _ttsVoiceDropdownValue(tts), // ignore: deprecated_member_use
              decoration: const InputDecoration(labelText: '音色'),
              items: [
                const DropdownMenuItem(
                  value: -1,
                  child: Text('系统默认（引擎自动）'),
                ),
                ...List.generate(
                  _ttsVoices.length,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(
                      '${_ttsVoices[i]['name']} · ${_ttsVoices[i]['locale']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: !tts.loaded
                  ? null
                  : (idx) async {
                      if (idx == null) return;
                      if (idx < 0) {
                        await ref.read(ttsVoiceSettingsProvider.notifier).setVoice(null);
                      } else if (idx < _ttsVoices.length) {
                        await ref.read(ttsVoiceSettingsProvider.notifier).setVoice(_ttsVoices[idx]);
                      }
                    },
            ),
            if (_ttsVoices.isEmpty && !_ttsVoicesLoading && tts.loaded)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '未读到该语言的音色列表：请先在系统中下载对应语音数据，再点「刷新」。',
                  style: TextStyle(color: scheme.error, fontSize: 12, height: 1.35),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '语速 ${_ttsSpeechRateLabel(tts.loaded ? tts.speechRate : 0.42)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Slider(
              value: tts.loaded ? tts.speechRate : 0.42,
              min: 0.25,
              max: 0.65,
              divisions: 16,
              label: _ttsSpeechRateLabel(tts.loaded ? tts.speechRate : 0.42),
              onChanged: !tts.loaded
                  ? null
                  : (v) => ref.read(ttsVoiceSettingsProvider.notifier).setSpeechRate(v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.volume_down_rounded, color: scheme.primary),
              title: const Text('氛围底噪'),
              subtitle: const Text('开播时会播放极低音量循环底噪；点「暂停本场播报」即停止整场与朗读。'),
            ),
            const Divider(height: 32),
            Text(
              'Night FM · AuraRadio',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              '版本 1.0.0+1 · DeepSeek API（OpenAI 兼容）· 本地 LiteRT / Gemma · Flutter',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
