import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/radio_broadcast_notifier.dart';
import '../widgets/topic_chips.dart';

class DiyRadioPage extends ConsumerStatefulWidget {
  const DiyRadioPage({super.key});

  @override
  ConsumerState<DiyRadioPage> createState() => _DiyRadioPageState();
}

class _DiyRadioPageState extends ConsumerState<DiyRadioPage> {
  final _controller = TextEditingController();
  String _preset = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(radioBroadcastProvider);
    final modelAsync = ref.watch(gemmaModelAvailableProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('DIY Radio Station'),
        actions: [
          if (s.phase != RadioPhase.idle)
            TextButton(
              onPressed: () => ref.read(radioBroadcastProvider.notifier).stopBroadcast(),
              child: const Text('Stop'),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            modelAsync.when(
              data: (ok) => ok
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Material(
                        color: const Color(0xFF2A2419),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.tertiary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'No Gemma model on device — demo script only (not real AI). '
                                  'Audio should still play via TTS after you tap Start.\n\n'
                                  'Add gemma-4-e2b-it.litertlm to app storage (see README) or bundle under assets/models/ to enable full radio.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFFD4C4A8),
                                        height: 1.35,
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
            ),
            Text(
              'Topic',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFE7ECF2),
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              onChanged: (_) => setState(() => _preset = ''),
              decoration: const InputDecoration(
                hintText: 'e.g. The Silk Road, lunar bases, anglerfish…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Presets',
              style: Theme.of(context).textTheme.titleSmall,
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
            const SizedBox(height: 28),
            FilledButton(
              onPressed: s.phase == RadioPhase.generating ||
                      s.phase == RadioPhase.loading ||
                      s.phase == RadioPhase.speaking
                  ? null
                  : () {
                      ref.read(radioBroadcastProvider.notifier).startBroadcast(
                            _controller.text,
                          );
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  s.phase == RadioPhase.loading || s.phase == RadioPhase.generating
                      ? 'Broadcasting…'
                      : 'Start Broadcast',
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (s.error != null)
              Text(
                s.error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            if (s.accumulatedText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                s.phase == RadioPhase.speaking ? 'On air' : 'Script',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Text(
                s.accumulatedText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.4,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              _phaseLabel(s.phase),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF7A8A99),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _phaseLabel(RadioPhase p) {
    switch (p) {
      case RadioPhase.idle:
        return 'Ready — set a topic and start when you are settled.';
      case RadioPhase.loading:
        return 'Warming the studio…';
      case RadioPhase.generating:
        return 'Writing a calm script (local model)…';
      case RadioPhase.speaking:
        return 'Playing — you can dim the screen; audio keeps the session.';
      case RadioPhase.error:
        return 'Something went wrong — try again or check the model file.';
    }
  }
}
