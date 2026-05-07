import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/night_fm_theme.dart';
import '../radio_station/application/llm_settings_notifier.dart';
import '../radio_station/presentation/pages/explore_radio_page.dart';
import '../radio_station/presentation/pages/library_radio_page.dart';
import '../radio_station/presentation/pages/night_fm_radio_page.dart';
import '../radio_station/presentation/pages/settings_radio_page.dart';

/// 渐变背景 + 底部导航 + 多 Tab。
class NightFmShell extends ConsumerStatefulWidget {
  const NightFmShell({super.key});

  @override
  ConsumerState<NightFmShell> createState() => _NightFmShellState();
}

class _NightFmShellState extends ConsumerState<NightFmShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(llmSettingsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NightFmColors.primaryFixed,
            NightFmColors.surfaceBright,
            NightFmColors.secondaryFixed,
          ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                NightFmRadioPage(),
                ExploreRadioPage(),
                LibraryRadioPage(),
                SettingsRadioPage(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.42),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavDot(
                          icon: Icons.radio_rounded,
                          filled: _index == 0,
                          onTap: () => setState(() => _index = 0),
                          tooltip: '电台',
                        ),
                        _NavDot(
                          icon: Icons.explore_rounded,
                          filled: _index == 1,
                          onTap: () => setState(() => _index = 1),
                          tooltip: '探索',
                        ),
                        _NavDot(
                          icon: Icons.bookmark_border_rounded,
                          filled: _index == 2,
                          onTap: () => setState(() => _index = 2),
                          tooltip: '收藏',
                        ),
                        _NavDot(
                          icon: Icons.settings_rounded,
                          filled: _index == 3,
                          onTap: () => setState(() => _index = 3),
                          tooltip: '设置',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavDot extends StatelessWidget {
  const _NavDot({
    required this.icon,
    required this.filled,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: filled ? Colors.white.withValues(alpha: 0.55) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 26,
            color: filled ? c.primary : const Color(0xFF666660).withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}
