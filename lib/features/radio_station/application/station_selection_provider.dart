import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前选中的「人格电台」索引，与 [NightFmStation.all] 对齐。
final stationSelectionProvider = StateProvider<int>((ref) => 0);
