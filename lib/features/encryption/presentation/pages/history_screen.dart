import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../../injection_container.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_event.dart';
import '../../../categories/presentation/bloc/category_state.dart';
import '../../domain/entities/encrypted_file.dart';
import '../cubits/history_cubit.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static Route<void> route() => MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (_) => sl<HistoryCubit>()..loadHistory(),
      child: const HistoryScreen(),
    ),
  );

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

/// Filter sentinel: `null` = All, `_kNoCategoryId` = Uncategorized, else a categoryId.
const String _kNoCategoryId = '__none__';

class _HistoryScreenState extends State<HistoryScreen> {
  String? _filterCategoryId; // null = All

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoryBloc>().add(const CategoriesLoadRequested());
    });
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Clear History'),
        content: const Text(
          'This permanently deletes all history records and the saved '
          'encrypted files on disk. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Clear',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<HistoryCubit>().clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          BlocBuilder<HistoryCubit, HistoryState>(
            builder: (context, state) {
              final hasItems =
                  state is HistoryLoaded && state.records.isNotEmpty;
              return IconButton(
                onPressed: hasItems ? () => _confirmClearAll(context) : null,
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  color: hasItems
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
                tooltip: 'Clear all',
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state is HistoryInitial) return const SizedBox.shrink();

          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HistoryError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () =>
                          context.read<HistoryCubit>().loadHistory(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is HistoryLoaded) {
            if (state.records.isEmpty) return const _EmptyHistory();

            return BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, catState) {
                final categories = catState.categories;
                final categoryById = {
                  for (final c in categories) c.id: c,
                };
                final filtered = _applyFilter(state.records);

                return Column(
                  children: [
                    _FilterBar(
                      categories: categories,
                      records: state.records,
                      selectedId: _filterCategoryId,
                      onChanged: (id) =>
                          setState(() => _filterCategoryId = id),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const _EmptyHistory()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                8,
                                16,
                                24,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final record = filtered[index];
                                return _HistoryItemCard(
                                  record: record,
                                  category: record.categoryId == null
                                      ? null
                                      : categoryById[record.categoryId],
                                  onDelete: () => context
                                      .read<HistoryCubit>()
                                      .deleteEntry(record.id),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  List<EncryptedFile> _applyFilter(List<EncryptedFile> all) {
    if (_filterCategoryId == null) return all;
    if (_filterCategoryId == _kNoCategoryId) {
      return all.where((r) => r.categoryId == null).toList();
    }
    return all.where((r) => r.categoryId == _filterCategoryId).toList();
  }
}

// ── Filter bar ─────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final List<Category> categories;
  final List<EncryptedFile> records;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _FilterBar({
    required this.categories,
    required this.records,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasUncategorized = records.any((r) => r.categoryId == null);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: selectedId == null,
              onSelected: (_) => onChanged(null),
            ),
            for (final c in categories) ...[
              const SizedBox(width: 8),
              FilterChip(
                label: Text(c.name),
                selected: selectedId == c.id,
                onSelected: (_) => onChanged(c.id),
              ),
            ],
            if (hasUncategorized) ...[
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Uncategorized'),
                selected: selectedId == _kNoCategoryId,
                onSelected: (_) => onChanged(_kNoCategoryId),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── History item card ──────────────────────────────────────────────────────

class _HistoryItemCard extends StatelessWidget {
  final EncryptedFile record;
  final Category? category;
  final VoidCallback onDelete;

  const _HistoryItemCard({
    required this.record,
    required this.category,
    required this.onDelete,
  });

  Future<void> _copyKey(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: record.secretKey));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Secret key copied to clipboard')),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete entry'),
        content: Text(
          'Delete this record and remove the encrypted file at:\n\n'
          '${record.encryptedPath}',
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

    if (confirmed == true) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate =
        DateFormat('MMM d, yyyy · HH:mm').format(record.createdAt.toLocal());

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.insert_drive_file_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.originalName,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            formattedDate,
                            style: theme.textTheme.labelSmall,
                          ),
                          if (record.categoryId != null) ...[
                            const SizedBox(width: 8),
                            _CategoryBadge(
                              label: category?.name ?? 'Unknown category',
                              color: _badgeColor(category?.name ?? '?'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(context),
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 10),
            _DetailRow(
              label: 'Encrypted file',
              value: p.basename(record.encryptedPath),
            ),
            const SizedBox(height: 6),
            _DetailRow(
              label: 'Secret key',
              value: record.secretKey,
              monospace: true,
              trailing: IconButton(
                onPressed: () => _copyKey(context),
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copy key',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;
  final Widget? trailing;

  const _DetailRow({
    required this.label,
    required this.value,
    this.monospace = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: theme.textTheme.labelSmall),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: monospace ? 'monospace' : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // ignore: use_null_aware_elements
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

Color _badgeColor(String name) {
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text('No history yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Encrypted files will appear here.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
