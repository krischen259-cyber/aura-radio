import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/station_selection_provider.dart';
import '../../data/night_fm_stations.dart';
import '../widgets/broadcast_topic_panel.dart';

/// 完整表单：电台人格 + 选题开播。
class ExploreRadioPage extends ConsumerWidget {
  const ExploreRadioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(stationSelectionProvider);
    final station =
        NightFmStation.all[idx.clamp(0, NightFmStation.all.length - 1)];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
          children: [
            Text(
              '探索节目',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              '先选择一档人格电台，再从预设文案出发改写今夜主题；也可完全自定义。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 20),
            Text('人格电台', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: idx,
              decoration: const InputDecoration(),
              items: [
                for (var i = 0; i < NightFmStation.all.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(
                        '${NightFmStation.all[i].nameZh} · ${NightFmStation.all[i].fmBand}'),
                  ),
              ],
              onChanged: (v) {
                if (v != null) {
                  ref.read(stationSelectionProvider.notifier).state = v;
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              station.subtitleZh,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            BroadcastTopicPanel(
              key: ValueKey(station.id),
              initialTopic: station.topicPrompt,
              stationLabel: station.nameZh,
              showGrabHandle: false,
            ),
          ],
        ),
      ),
    );
  }
}
