import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/bookmarks_notifier.dart';

/// 收藏的主题清单（会话内；退出应用后不保留）。
class LibraryRadioPage extends ConsumerWidget {
  const LibraryRadioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(bookmarksProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
        children: [
          Text(
            '我的收藏',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '在电台页播放时，点右上角心形即可收藏主题；此处可快速回看文案灵感。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 24),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Icons.bookmark_outline_rounded, size: 52, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    '还没有收藏',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '开播后点心形，把你喜欢的主题留在列表里。',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            )
          else
            for (final t in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey('bm_$t'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.15),
                    child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  ),
                  onDismissed: (_) => ref.read(bookmarksProvider.notifier).remove(t),
                  child: Card(
                    elevation: 0,
                    color: Colors.white.withValues(alpha: 0.55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      title: Text(t, maxLines: 3, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => ref.read(bookmarksProvider.notifier).remove(t),
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
