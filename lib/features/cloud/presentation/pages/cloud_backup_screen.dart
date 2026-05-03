import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_state.dart';
import '../../domain/entities/cloud_file.dart';
import '../cubits/cloud_backup_cubit.dart';
import '../cubits/cloud_backup_state.dart';

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});

  static Route<void> route() => MaterialPageRoute(
    builder: (_) => const CloudBackupScreen(),
  );

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  final Set<String> _expandedFolders = {};

  Future<void> _showRenameAndUploadDialog(BuildContext context) async {
    final cubit = context.read<CloudBackupCubit>();
    final controller = TextEditingController();
    Category? selectedCategory;

    final result = await showDialog<(String, Category?)>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Name your cloud backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter a name (e.g. backup1)',
                suffixText: '.enc',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                return DropdownButtonFormField<Category>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category (Optional)',
                  ),
                  items: [
                    const DropdownMenuItem<Category>(
                      value: null,
                      child: Text('Others'),
                    ),
                    ...state.categories.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                    ),
                  ],
                  onChanged: (val) => selectedCategory = val,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx, (text, selectedCategory));
              }
            },
            child: const Text('Pick File'),
          ),
        ],
      ),
    );

    if (result != null && result.$1.isNotEmpty && context.mounted) {
      cubit.pickAndUploadFile(
        result.$1,
        categoryName: result.$2?.name,
        categoryId: result.$2?.id,
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String fileName, {
    String? categoryName,
  }) async {
    final cubit = context.read<CloudBackupCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Cloud File?'),
        content: Text(
          'Are you sure you want to delete "$fileName" from the cloud?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      cubit.deleteFile(fileName, categoryName: categoryName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Backup'),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CloudBackupCubit>().loadCloudFiles(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRenameAndUploadDialog(context),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload File'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.black,
      ),
      body: BlocConsumer<CloudBackupCubit, CloudBackupState>(
        listener: (context, state) {
          if (state is CloudBackupError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is CloudBackupActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CloudBackupLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CloudBackupError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is CloudBackupLoaded) {
            if (state.files.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_queue,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No files in cloud',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            }

            // Group files by category
            final grouped = <String, List<CloudFile>>{};
            for (var file in state.files) {
              final cat = file.categoryName ?? 'Others';
              grouped.putIfAbsent(cat, () => []).add(file);
            }

            final categoriesList = grouped.keys.toList()
              ..sort((a, b) {
                if (a == 'Others') return 1;
                if (b == 'Others') return -1;
                return a.compareTo(b);
              });

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: categoriesList.length,
              itemBuilder: (context, catIndex) {
                final catName = categoriesList[catIndex];
                final catFiles = grouped[catName]!;
                final isExpanded = _expandedFolders.contains(catName);

                return Column(
                  children: [
                    _FolderTile(
                      name: catName,
                      fileCount: catFiles.length,
                      isExpanded: isExpanded,
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedFolders.remove(catName);
                          } else {
                            _expandedFolders.add(catName);
                          }
                        });
                      },
                    ),
                    if (isExpanded)
                      ...catFiles.map(
                        (file) => _CloudFileTile(
                          file: file,
                          transfer: state.transfers[file.name],
                          onDownload:
                              () => context
                                  .read<CloudBackupCubit>()
                                  .downloadFile(
                                    file.name,
                                    categoryName: file.categoryName,
                                  ),
                          onDelete:
                              () => _confirmDelete(
                                context,
                                file.name,
                                categoryName: file.categoryName,
                              ),
                          onPause:
                              () => context
                                  .read<CloudBackupCubit>()
                                  .pauseTransfer(file.name),
                          onResume:
                              () => context
                                  .read<CloudBackupCubit>()
                                  .resumeTransfer(file.name),
                          onCancel:
                              () => context
                                  .read<CloudBackupCubit>()
                                  .cancelTransfer(file.name),
                        ),
                      ),
                    const SizedBox(height: 8),
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
}

class _FolderTile extends StatelessWidget {
  final String name;
  final int fileCount;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FolderTile({
    required this.name,
    required this.fileCount,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.folder_open : Icons.folder,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleMedium),
                  Text(
                    '$fileCount ${fileCount == 1 ? 'file' : 'files'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudFileTile extends StatelessWidget {
  final CloudFile file;
  final CloudTransferProgress? transfer;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  const _CloudFileTile({
    required this.file,
    this.transfer,
    required this.onDownload,
    required this.onDelete,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        file.timeCreated != null
            ? DateFormat(
              'MMM d, yyyy · h:mm a',
            ).format(file.timeCreated!.toLocal())
            : 'Unknown date';
    final sizeStr = '${(file.sizeBytes / 1024).toStringAsFixed(1)} KB';

    return Container(
      margin: const EdgeInsets.only(left: 16, top: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateStr • $sizeStr',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (transfer == null) ...[
                IconButton(
                  tooltip: 'Download',
                  icon: const Icon(Icons.download_outlined, size: 20),
                  onPressed: onDownload,
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: onDelete,
                ),
              ] else ...[
                IconButton(
                  tooltip:
                      transfer!.status == CloudTransferStatus.paused
                          ? 'Resume'
                          : 'Pause',
                  icon: Icon(
                    transfer!.status == CloudTransferStatus.paused
                        ? Icons.play_arrow
                        : Icons.pause,
                    size: 20,
                  ),
                  onPressed: () {
                    if (transfer!.status == CloudTransferStatus.paused) {
                      onResume();
                    } else {
                      onPause();
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Cancel',
                  icon: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: onCancel,
                ),
              ],
            ],
          ),
          if (transfer != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: transfer!.totalBytes == 0 ? null : transfer!.fraction,
              minHeight: 2,
            ),
            const SizedBox(height: 4),
            Text(
              '${transfer!.kind == CloudTransferKind.upload ? 'Uploading' : 'Downloading'}'
              '${transfer!.status == CloudTransferStatus.paused ? ' (paused)' : ''} '
              '— ${(transfer!.fraction * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
