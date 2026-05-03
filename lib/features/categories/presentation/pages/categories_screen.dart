import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/category.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const CategoriesScreen());

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoryBloc>().add(const CategoriesLoadRequested());
    });
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Personal, Work, Bank',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Default Password (Optional)',
                hintText: 'Auto-fills on encrypt/decrypt',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              (nameController.text, passwordController.text),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.$1.trim().isNotEmpty && context.mounted) {
      context.read<CategoryBloc>().add(
        CategoryAddRequested(
          result.$1.trim(),
          defaultPassword: result.$2?.trim(),
        ),
      );
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    Category category,
  ) async {
    final nameController = TextEditingController(text: category.name);
    final passwordController = TextEditingController(
      text: category.defaultPassword,
    );
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Default Password (Optional)',
                hintText: 'Auto-fills on encrypt/decrypt',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              (nameController.text, passwordController.text),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      context.read<CategoryBloc>().add(
        CategoryUpdateRequested(
          id: category.id,
          newName: result.$1.trim().isNotEmpty ? result.$1.trim() : null,
          defaultPassword: result.$2?.trim(),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Category category,
  ) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Deleting "${category.name}" removes its salt. Files encrypted '
          'under this category will become unrecoverable via the category '
          'flow — you will need the original derived key to decrypt them.\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<CategoryBloc>().add(CategoryDeleteRequested(category.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<CategoryBloc, CategoryState>(
      listenWhen: (p, c) => p.error != c.error && c.error != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.error!)));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          actions: [
            IconButton(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add),
              tooltip: 'New category',
            ),
          ],
        ),
        body: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            if (state.loading && state.categories.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.categories.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No categories yet',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + to add one. Each category groups files under a '
                        'shared password.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: state.categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final c = state.categories[index];
                final color = _colorForName(c.name);
                final formatted = DateFormat(
                  'MMM d, yyyy',
                ).format(c.createdAt.toLocal());
                return Material(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.folder_outlined,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    c.name,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  if (c.defaultPassword != null) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.key_outlined,
                                      size: 14,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Created $formatted',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showEditDialog(context, c),
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          onPressed: () => _confirmDelete(context, c),
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Stable color from name hash so a given category looks consistent.
Color _colorForName(String name) {
  const palette = [
    Color(0xFFFFB74D),
    Color(0xFF4FC3F7),
    Color(0xFFB39DDB),
    Color(0xFFF06292),
    Color(0xFF81C784),
    Color(0xFFFF8A65),
    Color(0xFF64B5F6),
    Color(0xFFBA68C8),
  ];
  final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
  return palette[hash % palette.length];
}
