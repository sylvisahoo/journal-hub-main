import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

class SharedViewScreen extends ConsumerStatefulWidget {
  final String token;

  const SharedViewScreen({
    super.key,
    required this.token,
  });

  @override
  ConsumerState<SharedViewScreen> createState() => _SharedViewScreenState();
}

class _SharedViewScreenState extends ConsumerState<SharedViewScreen> {
  late Future<JournalEntry> _fetchEntryFuture;

  @override
  void initState() {
    super.initState();
    _fetchEntryFuture = ref.read(journalRepositoryProvider).fetchSharedEntry(widget.token);
  }

  String _formatDateFull(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Map category ID to user-friendly label (since categoryNames require auth)
  String _mapCategory(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return 'Uncategorized';
    if (categoryId == 'category-1') return 'Personal';
    if (categoryId == 'category-2') return 'Work';
    if (categoryId == 'category-3') return 'Ideas';
    if (categoryId == 'category-4') return 'Reflections';
    return categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Journal Entry', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Login'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<JournalEntry>(
        future: _fetchEntryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final errorStr = snapshot.error.toString();
            String message = 'Failed to load shared entry.';
            if (errorStr.contains('SHARE_REVOKED')) {
              message = 'This shared entry link has been revoked by the owner.';
            } else if (errorStr.contains('INVALID_SHARE_TOKEN')) {
              message = 'The shared link is invalid or expired.';
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.link_off_rounded, size: 72, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              ),
            );
          }

          final entry = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Card(
                  elevation: 0,
                  color: theme.colorScheme.primary.withOpacity(0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.public_rounded, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You are viewing a read-only shared copy of this journal entry.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title & Date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _mapCategory(entry.categoryId),
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${entry.wordCount} words',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  entry.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Published on ${_formatDateFull(entry.entryDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                const Divider(height: 32),

                // Body content
                _SharedMarkdownBodyRenderer(content: entry.content),
                const SizedBox(height: 40),

                // Tags if present
                if (entry.tagIds.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Tags',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.tagIds.map((t) {
                      // Strip tag- prefix if present for cleaner display
                      final label = t.startsWith('tag-') ? t.replaceFirst('tag-', '') : t;
                      return Chip(
                        label: Text('#$label', style: const TextStyle(fontSize: 12)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: theme.colorScheme.onSurface.withOpacity(0.04),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 48),

                // Bottom CTA
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Create your own secure journal today.',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.go('/register'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Get Started'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SharedMarkdownBodyRenderer extends StatelessWidget {
  final String content;

  const _SharedMarkdownBodyRenderer({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = content.split('\n');
    final List<Widget> bodyWidgets = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('### ')) {
        // Heading formatting
        bodyWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text(
              trimmed.substring(4),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('- ')) {
        // Bullet item formatting
        bodyWidgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 16, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                Expanded(
                  child: RichText(
                    text: _parseStyledText(trimmed.substring(2), theme),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Normal paragraph
        bodyWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: RichText(
              text: _parseStyledText(line, theme),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bodyWidgets,
    );
  }

  TextSpan _parseStyledText(String text, ThemeData theme) {
    final List<TextSpan> spans = [];
    final regExp = RegExp(r'(\*\*.*?\*\*|\*.*?\*)');
    int cursor = 0;

    final matches = regExp.allMatches(text);
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      
      final matchText = match.group(0)!;
      if (matchText.startsWith('**') && matchText.endsWith('**')) {
        spans.add(
          TextSpan(
            text: matchText.substring(2, matchText.length - 2),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      } else if (matchText.startsWith('*') && matchText.endsWith('*')) {
        spans.add(
          TextSpan(
            text: matchText.substring(1, matchText.length - 1),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      }
      
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return TextSpan(
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.8),
        height: 1.6,
      ),
      children: spans.isEmpty ? [TextSpan(text: text)] : spans,
    );
  }
}
