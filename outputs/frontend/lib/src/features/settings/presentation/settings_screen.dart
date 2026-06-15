import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeModeProvider);
    final categories = ref.watch(categoriesProvider);
    final tags = ref.watch(tagsProvider);

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
