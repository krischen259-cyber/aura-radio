import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookmarksProvider =
    NotifierProvider<BookmarksNotifier, List<String>>(BookmarksNotifier.new);

class BookmarksNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  bool contains(String topic) => state.contains(topic);

  void toggle(String topic) {
    final t = topic.trim();
    if (t.isEmpty) return;
    if (state.contains(t)) {
      state = [...state.where((e) => e != t)];
    } else {
      state = [...state, t];
    }
  }

  void remove(String topic) {
    state = [...state.where((e) => e != topic)];
  }
}
