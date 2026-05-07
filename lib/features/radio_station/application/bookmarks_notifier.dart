import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final bookmarksProvider =
    NotifierProvider<BookmarksNotifier, List<String>>(BookmarksNotifier.new);

class BookmarksNotifier extends Notifier<List<String>> {
  static const _prefsKey = 'bookmark_topics_v1';
  static const _maxItems = 40;

  @override
  List<String> build() => [];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final next = decoded
            .map((e) => '$e'.trim())
            .where((s) => s.isNotEmpty)
            .take(_maxItems)
            .toList();
        state = next;
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey, jsonEncode(state.take(_maxItems).toList()));
  }

  bool contains(String topic) => state.contains(topic);

  void toggle(String topic) {
    final t = topic.trim();
    if (t.isEmpty) return;
    if (state.contains(t)) {
      state = [...state.where((e) => e != t)];
    } else {
      final next = [...state.where((e) => e != t), t].take(_maxItems).toList();
      state = next;
    }
    _persist();
  }

  void remove(String topic) {
    state = [...state.where((e) => e != topic)];
    _persist();
  }
}
