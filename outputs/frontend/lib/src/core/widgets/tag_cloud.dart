import 'package:flutter/material.dart';
import '../models/models.dart';

class TagCloud extends StatelessWidget {
  final Map<String, int> tagDistribution;
  final List<Tag> allTags;
  final Function(String)? onTagSelected;

  const TagCloud({
    super.key,
    required this.tagDistribution,
    required this.allTags,
    this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (tagDistribution.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No tags logged yet.',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
        ),
      );
    }

    int minFreq = 999999;
    int maxFreq = 0;
    tagDistribution.forEach((key, val) {
      if (val < minFreq) minFreq = val;
      if (val > maxFreq) maxFreq = val;
    });

    final sortedTags = tagDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: sortedTags.map((entry) {
        final tagId = entry.key;
        final count = entry.value;

        // Resolve display name
        final tagObj = allTags.firstWhere(
          (t) => t.tagId == tagId,
          orElse: () => Tag(tagId: tagId, name: tagId.startsWith('tag-') ? tagId.replaceFirst('tag-', '') : tagId),
        );

        // Font size between 11.0 and 20.0
        double fontSize = 11.0;
        if (maxFreq > minFreq) {
          fontSize = 11.0 + ((count - minFreq) / (maxFreq - minFreq)) * 9.0;
        }

        final intensity = 0.4 + ((count - minFreq) / (maxFreq - minFreq == 0 ? 1 : maxFreq - minFreq)) * 0.6;

        return Tooltip(
          message: '$count entries',
          child: ActionChip(
            onPressed: onTagSelected != null ? () => onTagSelected!(tagId) : null,
            label: Text(
              '#${tagObj.name}',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: count == maxFreq ? FontWeight.bold : FontWeight.normal,
                color: theme.colorScheme.primary.withOpacity(intensity.clamp(0.4, 1.0)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.03),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.08),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }).toList(),
    );
  }
}
