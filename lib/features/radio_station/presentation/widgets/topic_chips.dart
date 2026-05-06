import 'package:flutter/material.dart';

class TopicChips extends StatelessWidget {
  const TopicChips({
    super.key,
    required this.onSelect,
    required this.selected,
  });

  final ValueChanged<String> onSelect;
  final String selected;

  static const presets = <String>[
    'Ancient History',
    'Space Exploration',
    'Deep Sea',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final label in presets)
          FilterChip(
            label: Text(label),
            selected: selected == label,
            onSelected: (_) => onSelect(label),
          ),
      ],
    );
  }
}
