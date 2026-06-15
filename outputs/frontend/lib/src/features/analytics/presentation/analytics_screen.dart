import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final analyticsState = ref.watch(analyticsProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: analyticsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading analytics: $err')),
        data: (analytics) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Header Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallSummaryCard(
                        theme,
                        label: 'Writing Streak',
                        value: '${analytics.writingStreak} Days',
                        icon: Icons.local_fire_department_rounded,
                        iconColor: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSmallSummaryCard(
                        theme,
                        label: 'Total Words',
                        value: '${analytics.totalWords}',
                        icon: Icons.notes_rounded,
                        iconColor: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Heatmap Calendar Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activity Density',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your writing activity over the past few weeks.',
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
                ),
                const SizedBox(height: 24),

                // Multi-panel layout on wide screens, column on mobile
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 800;
                    
                    final categoryCard = Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category Distribution',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (analytics.categoryDistribution.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Text('No categories logged yet.'),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: analytics.categoryDistribution.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final key = analytics.categoryDistribution.keys.elementAt(index);
                                  final count = analytics.categoryDistribution[key]!;
                                  final total = analytics.totalEntries == 0 ? 1 : analytics.totalEntries;
                                  final percent = count / total;
                                  
                                  // Find display name
                                  final categoryObj = categories.firstWhere(
                                    (c) => c.categoryId == key,
                                    orElse: () => Category(categoryId: '', name: key),
                                  );

                                  return _buildCategoryBar(
                                    theme,
                                    label: categoryObj.name,
                                    count: count,
                                    percentage: percent,
                                  );
                                },
                              ),
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
                            Text(
                              'Monthly Progress',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
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
                          Expanded(child: categoryCard),
                          const SizedBox(width: 24),
                          Expanded(child: progressCard),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          categoryCard,
                          const SizedBox(height: 24),
                          progressCard,
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSmallSummaryCard(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              foregroundColor: iconColor,
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapGrid(ThemeData theme, Map<DateTime, int> heatmapData) {
    // Generate dates for the last 5 weeks (35 days), ending today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 34));
    
    final List<DateTime> dates = [];
    for (int i = 0; i < 35; i++) {
      dates.add(startDate.add(Duration(days: i)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double boxSize = (constraints.maxWidth - (6 * 8)) / 7;
        
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

  Widget _buildCategoryBar(
    ThemeData theme, {
    required String label,
    required int count,
    required double percentage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('$count (${(percentage * 100).toInt()}%)', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: theme.brightness == Brightness.light
                ? Colors.grey.shade200
                : Colors.white.withOpacity(0.06),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressChart(ThemeData theme, List<int> monthlyWords) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final int maxWord = monthlyWords.reduce((curr, next) => curr > next ? curr : next);
    
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
