import 'package:flutter/material.dart';

const memoFilterTags = ['架构', 'UI库', '理念', '工作', '闪念'];

class TagFilterBar extends StatelessWidget {
  const TagFilterBar({
    super.key,
    required this.selectedTag,
    required this.onSelected,
    this.tags = memoFilterTags,
  });

  final String? selectedTag;
  final ValueChanged<String?> onSelected;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tag = index == 0 ? null : tags[index - 1];
          return ChoiceChip(
            key: ValueKey('memo-filter-${tag ?? 'all'}'),
            label: Text('#${tag ?? '全部'}'),
            selected: selectedTag == tag,
            onSelected: (_) => onSelected(tag),
          );
        },
      ),
    );
  }
}
