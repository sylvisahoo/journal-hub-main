import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' hide Category;
import 'package:file_picker/file_picker.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/file_saver.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref, ThemeData theme) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g., Personal, Health, Fitness',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                final repo = ref.read(journalRepositoryProvider);
                await repo.createCategory(name);
                ref.invalidate(categoriesProvider); // Force invalidate to rebuild lists
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Category "$name" created'), backgroundColor: Colors.teal),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog(BuildContext context, WidgetRef ref, ThemeData theme) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tag Name',
            hintText: 'e.g., productive, family, weekend',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim().toLowerCase().replaceAll('#', '');
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                final repo = ref.read(journalRepositoryProvider);
                await repo.createTag(name);
                ref.invalidate(tagsProvider); // Force invalidate to rebuild lists
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tag "#$name" created'), backgroundColor: Colors.teal),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(BuildContext context, WidgetRef ref, Category category) async {
    final repo = ref.read(journalRepositoryProvider);
    await repo.deleteCategory(category.categoryId);
    ref.invalidate(categoriesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Category "${category.name}" deleted'), backgroundColor: Colors.teal),
    );
  }

  void _deleteTag(BuildContext context, WidgetRef ref, Tag tag) async {
    final repo = ref.read(journalRepositoryProvider);
    await repo.deleteTag(tag.tagId);
    ref.invalidate(tagsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tag "#${tag.name}" deleted'), backgroundColor: Colors.teal),
    );
  }

  void _handleRestoreBackup(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String jsonContent;
      if (kIsWeb || file.bytes != null) {
        final bytes = file.bytes;
        if (bytes == null) throw Exception('Could not read file bytes');
        jsonContent = utf8.decode(bytes);
      } else {
        final path = file.path;
        if (path == null) throw Exception('File path is invalid');
        final ioFile = io.File(path);
        jsonContent = await ioFile.readAsString();
      }

      final data = json.decode(jsonContent);
      List<dynamic> entriesList;
      if (data is Map && data.containsKey('entries')) {
        entriesList = data['entries'] as List<dynamic>;
      } else if (data is List) {
        entriesList = data;
      } else {
        throw Exception('JSON format must be a list of entries or a map containing an "entries" list');
      }

      final List<Map<String, dynamic>> entries = entriesList.map((e) => Map<String, dynamic>.from(e)).toList();

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final repo = ref.read(journalRepositoryProvider);
      final importResult = await repo.importJournals(entries);
      
      ref.invalidate(allEntriesProvider);
      ref.invalidate(journalsProvider);
      ref.invalidate(analyticsProvider);

      if (context.mounted) {
        Navigator.pop(context); // Pop loading dialog
        final count = importResult['importedCount'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count journal entries successfully restored!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleExportBackup(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final repo = ref.read(journalRepositoryProvider);
      final entries = await repo.getEntries(); // Fetch all entries

      final mappedEntries = entries.map((entry) {
        return {
          'title': entry.title,
          'content': entry.content,
          'entryDate': entry.entryDate.toIso8601String(),
          'isPrivate': entry.isPrivate,
          'isEncrypted': entry.isEncrypted,
          'categoryId': entry.categoryId,
          'tags': entry.tagIds,
        };
      }).toList();

      final backupData = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'entries': mappedEntries,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      if (context.mounted) {
        Navigator.pop(context); // Pop loading dialog
      }

      final fileName = 'journal_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      if (kIsWeb) {
        saveBackupFile(jsonString, fileName);
      } else {
        final path = await FilePicker.platform.saveFile(
          fileName: fileName,
          bytes: Uint8List.fromList(utf8.encode(jsonString)),
        );
        if (path != null) {
          final file = io.File(path);
          await file.writeAsString(jsonString);
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup file exported successfully!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeModeProvider);
    final categories = ref.watch(categoriesProvider);
    final tags = ref.watch(tagsProvider);
    final goals = ref.watch(writingGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.go('/'),
              ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Mode Settings
            Text(
              'Appearance',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('System Default'),
                      value: ThemeMode.system,
                      groupValue: currentThemeMode,
                      onChanged: (mode) {
                        if (mode != null) {
                          ref.read(themeModeProvider.notifier).setTheme(mode);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Light Mode'),
                      value: ThemeMode.light,
                      groupValue: currentThemeMode,
                      onChanged: (mode) {
                        if (mode != null) {
                          ref.read(themeModeProvider.notifier).setTheme(mode);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark Mode'),
                      value: ThemeMode.dark,
                      groupValue: currentThemeMode,
                      onChanged: (mode) {
                        if (mode != null) {
                          ref.read(themeModeProvider.notifier).setTheme(mode);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),



            // Categories Manager
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manage Categories',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showAddCategoryDialog(context, ref, theme),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: categories.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('No categories created yet.')),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return ListTile(
                          title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () => _deleteCategory(context, ref, cat),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 32),

            // Tags Manager
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manage Tags',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showAddTagDialog(context, ref, theme),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: tags.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('No tags created yet.')),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map((tag) {
                          return Chip(
                            label: Text('#${tag.name}', style: const TextStyle(fontSize: 12)),
                            onDeleted: () => _deleteTag(context, ref, tag),
                            deleteIconColor: Colors.redAccent,
                            backgroundColor: theme.colorScheme.onSurface.withOpacity(0.04),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 32),

            // Writing Goals Settings
            Text(
              'Writing Goals',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daily Word Goal',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${goals.dailyWordGoal} words',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: goals.dailyWordGoal.toDouble().clamp(50.0, 2000.0),
                      min: 50.0,
                      max: 2000.0,
                      divisions: 39,
                      onChanged: (val) {
                        ref.read(writingGoalsProvider.notifier).setDailyWordGoal(val.toInt());
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Weekly Entries Goal',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${goals.weeklyEntryGoal} entries',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: goals.weeklyEntryGoal.toDouble().clamp(1.0, 7.0),
                      min: 1.0,
                      max: 7.0,
                      divisions: 6,
                      onChanged: (val) {
                        ref.read(writingGoalsProvider.notifier).setWeeklyEntryGoal(val.toInt());
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Backup & Restore
            Text(
              'Data Backup & Restore',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.file_upload_rounded, color: theme.colorScheme.primary),
                    title: const Text('Restore Backup (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Restore your journal entries from a JSON backup file'),
                    onTap: () => _handleRestoreBackup(context, ref),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.file_download_rounded, color: theme.colorScheme.primary),
                    title: const Text('Export Backup (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Download all your journal entries as a JSON backup file'),
                    onTap: () => _handleExportBackup(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Account',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
