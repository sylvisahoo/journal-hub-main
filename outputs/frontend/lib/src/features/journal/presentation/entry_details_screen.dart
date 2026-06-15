import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

class EntryDetailsScreen extends ConsumerStatefulWidget {
  final String entryId;

  const EntryDetailsScreen({
    super.key,
    required this.entryId,
  });

  @override
  ConsumerState<EntryDetailsScreen> createState() => _EntryDetailsScreenState();
}

class _EntryDetailsScreenState extends ConsumerState<EntryDetailsScreen> {
  bool _isGeneratingLink = false;
  String? _generatedShareLink;

  void _handleDelete(BuildContext context, JournalEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('Are you sure you want to permanently delete this journal entry? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Pop confirm dialog
              
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );

              try {
                await ref.read(journalsProvider.notifier).deleteEntry(entry.journalId);
                if (mounted) {
                  Navigator.pop(context); // Pop loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Entry deleted successfully'), backgroundColor: Colors.teal),
                  );
                  context.go('/journals');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Pop loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _toggleShareLink(JournalEntry entry) async {
    if (entry.isPrivate) {
      // Prompt user to make it public first or offer to change it
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Make Entry Public?'),
          content: const Text('This entry is currently private. To generate a shareable link, you must update its privacy setting to Public.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final updated = entry.copyWith(isPrivate: false);
                await ref.read(journalsProvider.notifier).updateEntry(updated);
                _generateLink(entry.journalId);
              },
              child: const Text('Make Public & Share'),
            ),
          ],
        ),
      );
    } else {
      _generateLink(entry.journalId);
    }
  }

  void _generateLink(String entryId) async {
    setState(() {
      _isGeneratingLink = true;
    });

    try {
      final repo = ref.read(journalRepositoryProvider);
      final link = await repo.generateShareLink(entryId);
      setState(() {
        _generatedShareLink = link;
        _isGeneratingLink = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingLink = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating link: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _copyShareLink() {
    if (_generatedShareLink != null) {
      Clipboard.setData(ClipboardData(text: _generatedShareLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Link copied to clipboard!'),
            ],
          ),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final journalsState = ref.watch(journalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Entry', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: journalsState.when(
          loading: () => [],
          error: (_, __) => [],
          data: (entries) {
            final entryIndex = entries.indexWhere((e) => e.journalId == widget.entryId);
            if (entryIndex == -1) return [];
            final entry = entries[entryIndex];

            return [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _toggleShareLink(entry),
                tooltip: 'Share Entry',
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.go('/journals/${entry.journalId}/edit'),
                tooltip: 'Edit Entry',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () => _handleDelete(context, entry),
                tooltip: 'Delete Entry',
              ),
              const SizedBox(width: 8),
            ];
          },
        ),
      ),
      body: journalsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (entries) {
          final entryIndex = entries.indexWhere((e) => e.journalId == widget.entryId);
          if (entryIndex == -1) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text('Journal Entry Not Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/journals'),
                    child: const Text('Back to Journals'),
                  ),
                ],
              ),
            );
          }

          final entry = entries[entryIndex];
          final categories = ref.watch(categoriesProvider);
          final tags = ref.watch(tagsProvider);

          final category = categories.firstWhere(
            (c) => c.categoryId == entry.categoryId,
            orElse: () => const Category(categoryId: '', name: 'Uncategorized'),
          );

          final entryTags = tags.where((t) => entry.tagIds.contains(t.tagId)).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Share Sheet Simulation if generated
                if (_generatedShareLink != null) ...[
                  _buildShareSheet(theme),
                  const SizedBox(height: 24),
                ],

                // Metadata details
                Row(
                  children: [
                    if (entry.categoryId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category.name,
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Icon(
                      entry.isPrivate ? Icons.lock_outline_rounded : Icons.public_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.isPrivate ? 'Private' : 'Publicly Shared',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
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
                const SizedBox(height: 20),

                // Title
                Text(
                  entry.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Date
                Text(
                  'Written on ${_formatDateFull(entry.entryDate)} (last updated ${_formatDateFull(entry.updatedAt)})',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                const Divider(height: 32),

                // Content body with mock parser
                _MarkdownBodyRenderer(content: entry.content),
                const SizedBox(height: 40),

                // Tags section
                if (entryTags.isNotEmpty) ...[
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
                    children: entryTags.map((t) {
                      return Chip(
                        label: Text('#${t.name}', style: const TextStyle(fontSize: 12)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: theme.colorScheme.onSurface.withOpacity(0.04),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShareSheet(ThemeData theme) {
    return Card(
      color: theme.colorScheme.primary.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.share_rounded, color: Colors.teal, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Secure Shared Link Generated',
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(() => _generatedShareLink = null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Anyone with this link can read a secure, read-only copy of this entry:',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _generatedShareLink!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _copyShareLink,
                  icon: const Icon(Icons.copy_all_rounded, size: 16),
                  label: const Text('Copy'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
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

class _MarkdownBodyRenderer extends StatelessWidget {
  final String content;

  const _MarkdownBodyRenderer({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = content.split('\n');
    final List<Widget> bodyWidgets = [];

    for (final line in lines) {
      if (line.trim().startsWith('- ')) {
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
                    text: _parseStyledText(line.trim().substring(2), theme),
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
    // Basic parser for Bold (**) and Italic (*)
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
