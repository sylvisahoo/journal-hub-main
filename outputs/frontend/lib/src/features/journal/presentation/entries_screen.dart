import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

class EntriesScreen extends ConsumerStatefulWidget {
  const EntriesScreen({super.key});

  @override
  ConsumerState<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends ConsumerState<EntriesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controller with current provider value
    Future.microtask(() {
      _searchController.text = ref.read(searchQueryProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredEntriesState = ref.watch(filteredEntriesProvider);
    final categories = ref.watch(categoriesProvider);
    final tags = ref.watch(tagsProvider);

    final selectedCat = ref.watch(selectedCategoryFilterProvider);
    final selectedTag = ref.watch(selectedTagFilterProvider);
    final selectedDateRange = ref.watch(selectedDateRangeFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entries', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go('/journals/create'),
            tooltip: 'New Entry',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search title or content...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      ref.read(searchQueryProvider.notifier).state = val;
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),

          // Filters Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Category Filter Chip
                DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: selectedCat,
                    hint: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category_outlined, size: 16),
                          const SizedBox(width: 6),
                          Text('Category', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.7))),
                        ],
                      ),
                    ),
                    selectedItemBuilder: (context) {
                      return [
                        const DropdownMenuItem(value: null, child: Text('All Categories')),
                        ...categories.map((c) => DropdownMenuItem(
                          value: c.categoryId,
                          child: Text(c.name),
                        )),
                      ];
                    },
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...categories.map((cat) {
                        return DropdownMenuItem<String?>(
                          value: cat.categoryId,
                          child: Text(cat.name),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      ref.read(selectedCategoryFilterProvider.notifier).state = val;
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Tag Filter Chip
                DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: selectedTag,
                    hint: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_offer_outlined, size: 16),
                          const SizedBox(width: 6),
                          Text('Tag', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.7))),
                        ],
                      ),
                    ),
                    selectedItemBuilder: (context) {
                      return [
                        const DropdownMenuItem(value: null, child: Text('All Tags')),
                        ...tags.map((t) => DropdownMenuItem(
                          value: t.tagId,
                          child: Text('#${t.name}'),
                        )),
                      ];
                    },
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Tags'),
                      ),
                      ...tags.map((tag) {
                        return DropdownMenuItem<String?>(
                          value: tag.tagId,
                          child: Text('#${tag.name}'),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      ref.read(selectedTagFilterProvider.notifier).state = val;
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Date Range Picker Chip
                ActionChip(
                  avatar: Icon(Icons.date_range_rounded, size: 16, color: selectedDateRange != null ? theme.colorScheme.primary : null),
                  label: Text(
                    selectedDateRange == null
                        ? 'Date Range'
                        : '${_formatDateShort(selectedDateRange.start)} - ${_formatDateShort(selectedDateRange.end)}',
                    style: TextStyle(fontSize: 12, color: selectedDateRange != null ? theme.colorScheme.primary : null),
                  ),
                  onPressed: () async {
                    final dateRange = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2025),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: selectedDateRange,
                    );
                    if (dateRange != null) {
                      ref.read(selectedDateRangeFilterProvider.notifier).state = dateRange;
                    }
                  },
                ),
                const SizedBox(width: 8),

                // Reset Filter Button
                if (selectedCat != null || selectedTag != null || selectedDateRange != null || _searchController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                      ref.read(selectedCategoryFilterProvider.notifier).state = null;
                      ref.read(selectedTagFilterProvider.notifier).state = null;
                      ref.read(selectedDateRangeFilterProvider.notifier).state = null;
                      setState(() {});
                    },
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 14),
                    label: const Text('Clear Filters', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),

          // Active filter details banner
          if (selectedCat != null || selectedTag != null || selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Text(
                    'Active filters: ',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                  if (selectedCat != null)
                    _buildActiveChip(categories.firstWhere((c) => c.categoryId == selectedCat).name, () {
                      ref.read(selectedCategoryFilterProvider.notifier).state = null;
                    }, theme),
                  if (selectedTag != null)
                    _buildActiveChip('#${tags.firstWhere((t) => t.tagId == selectedTag).name}', () {
                      ref.read(selectedTagFilterProvider.notifier).state = null;
                    }, theme),
                  if (selectedDateRange != null)
                    _buildActiveChip('${_formatDateShort(selectedDateRange.start)} - ${_formatDateShort(selectedDateRange.end)}', () {
                      ref.read(selectedDateRangeFilterProvider.notifier).state = null;
                    }, theme),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Entries List
          Expanded(
            child: filteredEntriesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading entries: $err')),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        const Text('No entries found matching filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Try adjusting your search query or filters.'),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: entries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _buildEntryItem(context, entry, theme, ref);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChip(String label, VoidCallback onDeleted, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDeleted,
            child: Icon(Icons.close_rounded, size: 12, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryItem(BuildContext context, JournalEntry entry, ThemeData theme, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final tags = ref.watch(tagsProvider);
    
    final category = categories.firstWhere(
      (c) => c.categoryId == entry.categoryId,
      orElse: () => const Category(categoryId: '', name: 'Uncategorized'),
    );

    final entryTags = tags.where((t) => entry.tagIds.contains(t.tagId)).toList();

    return InkWell(
      onTap: () => context.go('/journals/${entry.journalId}'),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (entry.categoryId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category.name,
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateFull(entry.entryDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    entry.isPrivate ? Icons.lock_outline_rounded : Icons.public_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                entry.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
              if (entryTags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entryTags.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${t.name}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateFull(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.month}/${date.day}/${date.year.toString().substring(2)}';
  }
}
