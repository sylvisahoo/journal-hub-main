import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final yearMonthStr = "${_focusedDay.year}-${_focusedDay.month}";

    // Watch calendar dates (highlights) for current focused month/year
    final highlightedDatesState = ref.watch(calendarDatesProvider(yearMonthStr));

    // Watch entries for the selected day
    final selectedDay = _selectedDay ?? _focusedDay;
    final selectedDayEntriesState = ref.watch(calendarEntriesProvider(selectedDay));

    final calendarCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar<Object>(
          firstDay: DateTime(2025, 1, 1),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) {
            final dateKey = _formatDateKey(day);
            final highlights = highlightedDatesState.value ?? [];
            return highlights.contains(dateKey) ? [true] : const [];
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 1,
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
          ),
        ),
      ),
    );

    final timelineSection = Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Text(
                _selectedDay == null
                    ? 'Select a day to view entries'
                    : 'Entries for ${_formatDateFull(_selectedDay!)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            selectedDayEntriesState.when(
              loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
              error: (err, _) => Expanded(child: Center(child: Text('Error loading journal entries: $err'))),
              data: (selectedDayEntries) {
                if (selectedDayEntries.isEmpty) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_note_rounded,
                            size: 48,
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No entries for this day',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              context.go('/journals/create');
                            },
                            icon: const Icon(Icons.edit_note_rounded),
                            label: const Text('Write Entry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Expanded(
                  child: ListView.builder(
                    itemCount: selectedDayEntries.length,
                    itemBuilder: (context, index) {
                      final entry = selectedDayEntries[index];
                      return _buildDailyEntryTile(context, entry, theme, ref);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar View', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;

          if (isWide) {
            // Side-by-side layout on desktop/web
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: calendarCard,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 4,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            timelineSection,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Vertical layout on mobile
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  calendarCard,
                  const SizedBox(height: 16),
                  timelineSection,
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDailyEntryTile(BuildContext context, JournalEntry entry, ThemeData theme, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final category = categories.firstWhere(
      (c) => c.categoryId == entry.categoryId,
      orElse: () => const Category(categoryId: '', name: 'Uncategorized'),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          entry.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              entry.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (entry.categoryId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category.name,
                      style: TextStyle(fontSize: 10, color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(entry.isPrivate ? Icons.lock_outline_rounded : Icons.public_rounded, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${entry.wordCount} words',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: () => context.go('/journals/${entry.journalId}'),
      ),
    );
  }

  String _formatDateFull(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
