import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/bookmarks_notifier.dart';
import '../../application/radio_broadcast_notifier.dart';
import '../../application/station_selection_provider.dart';
import '../../data/night_fm_stations.dart';
import '../widgets/broadcast_topic_panel.dart';

/// Stitch 风格电台主页：渐变、玻璃拟态、横向电台条与选题开播。
class NightFmRadioPage extends ConsumerStatefulWidget {
  const NightFmRadioPage({super.key});

  @override
  ConsumerState<NightFmRadioPage> createState() => _NightFmRadioPageState();
}

class _NightFmRadioPageState extends ConsumerState<NightFmRadioPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _breath;
  Timer? _tick;
  var _elapsedSec = 0;

  static const _coverUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCiKL7UPzuAcXCp8IBTthkJQT30F5qvtRVHACFxyhKq3Vco7xVJXblmVL2xmMURojJNI2vrEGU2RiCtQRHy7Yo_SSCiyvGm_vXNXfMJ3poSwdf7cUKIXbQMA4zoBxwG8jBSUDysvaVk-FJ427CpiBCc9dV2JnaNUKSsRBmFDy9zm5oLk-QDNb1sfkPamaPfrmWI8OP5_all69TDCoDhBZ1CsnzpeHYdaNMAp0gNsYzsJS-V52Sjc-4HQObqitIVGmzXPURYuQxYqVo';

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tick?.cancel();
    _breath.dispose();
    super.dispose();
  }

  void _syncTimer(RadioPhase phase) {
    final active = phase == RadioPhase.loading ||
        phase == RadioPhase.generating ||
        phase == RadioPhase.speaking;
    if (active) {
      _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsedSec++);
      });
    } else {
      _tick?.cancel();
      _tick = null;
      _elapsedSec = 0;
    }
  }

  String _formatMmSs(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _openTopicSheet(NightFmStation station) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      backgroundColor: Colors.white.withValues(alpha: 0.94),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: BroadcastTopicPanel(
                initialTopic: station.topicPrompt,
                stationLabel: station.nameZh,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final idx = ref.watch(stationSelectionProvider);
    final station =
        NightFmStation.all[idx.clamp(0, NightFmStation.all.length - 1)];
    final s = ref.watch(radioBroadcastProvider);
    _syncTimer(s.phase);

    final live = s.phase == RadioPhase.loading ||
        s.phase == RadioPhase.generating ||
        s.phase == RadioPhase.speaking;

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: Drawer(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
          children: [
            Text('Night FM', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '本地 AI 轻柔电台 · AuraRadio',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const Divider(height: 40),
            ListTile(
              leading: const Icon(Icons.nightlight_round),
              title: const Text('入睡小贴士'),
              subtitle: const Text('尽量调暗屏幕；播报时可锁屏聆听（视系统而定）。'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.graphic_eq),
              title: const Text('关于音色'),
              subtitle: const Text('朗读跟随系统 TTS，可在系统设置中更换中英文发音人。'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _topChrome(context)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 140),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _stationHeader(context, station, idx),
                        const SizedBox(height: 28),
                        _liveBadge(context, live),
                        const SizedBox(height: 28),
                        _albumArt(),
                        const SizedBox(height: 36),
                        _progressPulse(),
                        const SizedBox(height: 28),
                        _trackMeta(context, s, station),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            itemCount: NightFmStation.all.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final st = NightFmStation.all[i];
                              final sel = i == idx;
                              return ChoiceChip(
                                label: Text(st.nameZh),
                                selected: sel,
                                onSelected: (_) {
                                  ref
                                      .read(stationSelectionProvider.notifier)
                                      .state = i;
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed:
                              live ? null : () => _openTopicSheet(station),
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('选题开播'),
                        ),
                        if (s.accumulatedText.trim().isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '文稿',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.55)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                s.accumulatedText,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(height: 1.45),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => ref
                                    .read(radioBroadcastProvider.notifier)
                                    .replayAccumulatedSpeech(),
                                icon: const Icon(Icons.volume_up_rounded, size: 20),
                                label: const Text('朗读文稿'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => ref
                                    .read(radioBroadcastProvider.notifier)
                                    .stopSpeechOnly(),
                                icon:
                                    const Icon(Icons.stop_circle_outlined, size: 20),
                                label: const Text('停止朗读'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (live)
              Positioned(
                left: 24,
                right: 24,
                bottom: 12,
                child: FilledButton.tonal(
                  onPressed: () =>
                      ref.read(radioBroadcastProvider.notifier).stopBroadcast(),
                  child: const Text('暂停本场播报'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _topChrome(BuildContext context) {
    final s = ref.watch(radioBroadcastProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final topicKey = s.activeTopic ?? '';
    final starred = topicKey.isNotEmpty && bookmarks.contains(topicKey);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              icon: const Icon(Icons.menu_rounded, size: 28),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: Text(
              'Night FM',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.6,
                  ),
            ),
          ),
          IconButton(
            onPressed: topicKey.isEmpty
                ? null
                : () => ref.read(bookmarksProvider.notifier).toggle(topicKey),
            icon: Icon(
              starred ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: starred
                  ? Colors.redAccent
                  : Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stationHeader(BuildContext context, NightFmStation station, int idx) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            final n = NightFmStation.all.length;
            ref.read(stationSelectionProvider.notifier).state =
                (idx - 1 + n) % n;
          },
          icon: Icon(Icons.chevron_left,
              color: Theme.of(context).colorScheme.outlineVariant),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                station.nameZh,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      letterSpacing: 8,
                      fontWeight: FontWeight.w300,
                      fontSize: 26,
                    ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 0.5,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.35),
              ),
              const SizedBox(height: 10),
              Text(
                station.fmBand,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 4,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.55),
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            final n = NightFmStation.all.length;
            ref.read(stationSelectionProvider.notifier).state = (idx + 1) % n;
          },
          icon: Icon(Icons.chevron_right,
              color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ],
    );
  }

  Widget _liveBadge(BuildContext context, bool live) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                live ? '直播中' : '待机',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _albumArt() {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              boxShadow: const [
                BoxShadow(
                    blurRadius: 40, spreadRadius: -4, color: Color(0x22000000)),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _breath,
            builder: (context, child) {
              final scale = 1.0 + (_breath.value * 0.02);
              return Transform.scale(scale: scale, child: child);
            },
            child: ClipOval(
              child: Image.network(
                _coverUrl,
                width: 192,
                height: 192,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 192,
                  height: 192,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFB8D4E6), Color(0xFFE8F0EA)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.graphic_eq_rounded,
                      size: 56, color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressPulse() {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final shift = _breath.value * 80 - 40;
        return SizedBox(
          width: 180,
          height: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.25)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(shift, 0),
                    child: Container(
                      width: 64,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.38),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _trackMeta(
      BuildContext context, RadioUiState s, NightFmStation station) {
    final phase = s.phase;
    String title;
    if (phase == RadioPhase.loading || phase == RadioPhase.generating) {
      title = '正在书写今夜文稿…';
    } else if (s.accumulatedText.trim().isNotEmpty) {
      final line = s.accumulatedText.trim().split(RegExp(r'\n')).first.trim();
      title = line.length > 40 ? '${line.substring(0, 40)}…' : line;
    } else {
      title = '月光下的宁静';
    }

    final timer = _formatMmSs(_elapsedSec);
    String sub;
    if (phase == RadioPhase.speaking) {
      sub = '${station.subtitleZh} · 语音播报 · $timer';
    } else if (_livePhase(phase)) {
      sub = '${station.subtitleZh} · 准备声音 · $timer';
    } else {
      sub = '${station.subtitleZh} · ${station.fmBand}';
    }

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.72),
                letterSpacing: 0.3,
              ),
        ),
      ],
    );
  }

  bool _livePhase(RadioPhase phase) =>
      phase == RadioPhase.loading ||
      phase == RadioPhase.generating ||
      phase == RadioPhase.speaking;
}
