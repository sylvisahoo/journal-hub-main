import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/tag_cloud.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.value;

    final journalsState = ref.watch(recentEntriesProvider);
    final analyticsState = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(allEntriesProvider);
              ref.invalidate(analyticsProvider);
            },
          ),
          if (ResponsiveLayout.isMobile(context))
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.go('/settings'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: journalsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text('Error loading dashboard: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(allEntriesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (entries) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                Text(
                  'Hello, ${user?.fullName ?? "Writer"} 👋',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Capture your thoughts and track your journey.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),

                // Goals Progress Card
                Builder(
                  builder: (context) {
                    final goals = ref.watch(writingGoalsProvider);
                    final allEntries = ref.watch(allEntriesProvider).value ?? [];
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final todayWords = allEntries
                        .where((e) => DateTime(e.entryDate.year, e.entryDate.month, e.entryDate.day).isAtSameMomentAs(today))
                        .fold<int>(0, (sum, e) => sum + e.wordCount);
                    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
                    final weeklyEntries = allEntries
                        .where((e) => e.entryDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))))
                        .length;

                    final dailyProgress = (todayWords / goals.dailyWordGoal).clamp(0.0, 1.0);
                    final weeklyProgress = (weeklyEntries / goals.weeklyEntryGoal).clamp(0.0, 1.0);

                    return Card(
                      elevation: 0,
                      color: theme.colorScheme.secondary.withOpacity(0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.15)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.track_changes_rounded, color: theme.colorScheme.secondary),
                                const SizedBox(width: 8),
                                Text(
                                  'Writing Goals & Progress',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 600;
                                final progressWidgets = [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Daily Words',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '$todayWords / ${goals.dailyWordGoal} words',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: dailyProgress,
                                          minHeight: 8,
                                          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.06),
                                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Weekly Entries',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '$weeklyEntries / ${goals.weeklyEntryGoal} entries',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.secondary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: weeklyProgress,
                                          minHeight: 8,
                                          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.06),
                                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ];

                                return isMobile
                                    ? Column(
                                        children: [
                                          progressWidgets[0],
                                          const SizedBox(height: 16),
                                          progressWidgets[1],
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(child: progressWidgets[0]),
                                          const SizedBox(width: 24),
                                          Expanded(child: progressWidgets[1]),
                                        ],
                                      );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
                const SizedBox(height: 32),

                analyticsState.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                  data: (analytics) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final useSingleColumn = constraints.maxWidth < 600;
                          return GridView.count(
                            crossAxisCount: useSingleColumn ? 1 : 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: useSingleColumn ? 3.0 : 1.8,
                            children: [
                              _buildStatCard(
                                context,
                                title: 'Writing Streak',
                                value: '${analytics.writingStreak} days',
                                icon: Icons.local_fire_department_rounded,
                                color: Colors.orange,
                              ),
                              _buildStatCard(
                                context,
                                title: 'Total Entries',
                                value: '${analytics.totalEntries}',
                                icon: Icons.book_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              _buildStatCard(
                                context,
                                title: 'Total Words',
                                value: '${analytics.totalWords}',
                                icon: Icons.notes_rounded,
                                color: theme.colorScheme.secondary,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildTrendsSection(context, theme, analytics),
                      const SizedBox(height: 24),
                      _buildTagCloudCard(context, theme, analytics, ref),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Prompt Section
                _buildPromptSection(context, theme),
                const SizedBox(height: 32),

                // Recent entries list header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Entries',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/journals'),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (entries.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.auto_stories_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurface.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Your journal is empty',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Write your first entry and begin your digital reflection.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/journals/create'),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create Entry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length > 3 ? 3 : entries.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _buildRecentEntryCard(context, entry, theme, ref);
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/journals/create'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        tooltip: 'Write new entry',
        child: const Icon(Icons.edit_note_rounded, size: 28),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSection(BuildContext context, ThemeData theme) {
    final prompts = [
      'What are three things you are grateful for today?',
      'Describe a recent challenge and what it taught you.',
      'Where do you see yourself in five years?',
      'Write about a person who has had a positive impact on your life.'
    ];

    return Card(
      color: theme.colorScheme.primary.withOpacity(0.04),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Daily Writing Prompts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Select a prompt to jumpstart your writing session:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: prompts.map((prompt) {
                return InkWell(
                  onTap: () {
                    // Navigate to editor screen and prefill prompt title
                    context.go('/journals/create?prompt=${Uri.encodeComponent(prompt)}');
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      prompt,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntryCard(
    BuildContext context,
    JournalEntry entry,
    ThemeData theme,
    WidgetRef ref,
  ) {
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
                        _formatDate(entry.entryDate),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              if (entryTags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  children: entryTags.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${t.name}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildTagCloudCard(
    BuildContext context,
    ThemeData theme,
    AnalyticsData analytics,
    WidgetRef ref,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Popular Tags',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select a tag to filter your entries.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TagCloud(
                tagDistribution: analytics.tagDistribution,
                allTags: ref.watch(tagsProvider),
                onTagSelected: (tagId) {
                  ref.read(selectedTagFilterProvider.notifier).state = tagId;
                  context.go('/journals');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsSection(BuildContext context, ThemeData theme, AnalyticsData analytics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        
        final heatmapCard = Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Activity Density',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your writing frequency over the past 5 weeks.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                _buildHeatmapGrid(theme, analytics.heatmapData),
                const SizedBox(height: 16),
                _buildHeatmapLegend(theme),
              ],
            ),
          ),
        );

        final progressCard = Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Monthly Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total words written per month.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                _buildProgressChart(theme, analytics.monthlyWords),
              ],
            ),
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: heatmapCard),
              const SizedBox(width: 24),
              Expanded(child: progressCard),
            ],
          );
        } else {
          return Column(
            children: [
              heatmapCard,
              const SizedBox(height: 24),
              progressCard,
            ],
          );
        }
      },
    );
  }

  Widget _buildHeatmapGrid(ThemeData theme, Map<DateTime, int> heatmapData) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 34));
    
    final List<DateTime> dates = [];
    for (int i = 0; i < 35; i++) {
      dates.add(startDate.add(Duration(days: i)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 35,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final date = dates[index];
            final count = heatmapData[date] ?? 0;
            
            Color boxColor;
            if (count == 0) {
              boxColor = theme.brightness == Brightness.light
                  ? Colors.grey.shade200
                  : Colors.white.withOpacity(0.06);
            } else if (count == 1) {
              boxColor = theme.colorScheme.primary.withOpacity(0.3);
            } else if (count == 2) {
              boxColor = theme.colorScheme.primary.withOpacity(0.6);
            } else {
              boxColor = theme.colorScheme.primary;
            }

            return Tooltip(
              message: '${date.month}/${date.day}/${date.year}: $count entries',
              child: Container(
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeatmapLegend(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4))),
        const SizedBox(width: 4),
        _buildLegendBox(theme.brightness == Brightness.light ? Colors.grey.shade200 : Colors.white.withOpacity(0.06)),
        _buildLegendBox(theme.colorScheme.primary.withOpacity(0.3)),
        _buildLegendBox(theme.colorScheme.primary.withOpacity(0.6)),
        _buildLegendBox(theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text('More', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4))),
      ],
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildProgressChart(ThemeData theme, List<int> monthlyWords) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final int maxWord = monthlyWords.isNotEmpty ? monthlyWords.reduce((curr, next) => curr > next ? curr : next) : 0;
    
    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(monthlyWords.length, (index) {
          final word = monthlyWords[index];
          final percent = word / (maxWord == 0 ? 1 : maxWord);
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$word',
                style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                width: 28,
                height: 140 * percent,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.6),
                      theme.colorScheme.primary,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                months[index],
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            ],
          );
        }),
      ),
    );
  }
}
