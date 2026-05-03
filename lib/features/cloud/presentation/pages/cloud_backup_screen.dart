import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubits/cloud_backup_cubit.dart';
import '../cubits/cloud_backup_state.dart';

class CloudBackupScreen extends StatelessWidget {
  const CloudBackupScreen({super.key});

  static Route route() => MaterialPageRoute(
    builder: (_) => const CloudBackupScreen(),
  );

  Future<void> _showRenameAndUploadDialog(BuildContext context) async {
    final cubit = context.read<CloudBackupCubit>();
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Name your cloud backup'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter a name (e.g. backup1)',
            suffixText: '.enc',
          ),
          autofocus: true,
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
                Navigator.pop(ctx, text);
              }
            },
            child: const Text('Pick File'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      cubit.pickAndUploadFile(result);
    }
  }

  Future<void> _confirmDelete(BuildContext context, String fileName) async {
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
      cubit.deleteFile(fileName);
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
            return ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ).copyWith(bottom: 100),
              itemCount: state.files.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final file = state.files[index];
                final dateStr = file.timeCreated != null
                    ? DateFormat(
                        'MMM d, yyyy · h:mm a',
                      ).format(file.timeCreated!.toLocal())
                    : 'Unknown date';
                final sizeStr =
                    '${(file.sizeBytes / 1024).toStringAsFixed(1)} KB';

                final transfer = state.transfers[file.name];
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFB39DDB,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.cloud_done_outlined,
                              color: Color(0xFFB39DDB),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$dateStr • $sizeStr',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (transfer == null) ...[
                            IconButton(
                              tooltip: 'Download',
                              icon: const Icon(Icons.download_outlined),
                              onPressed: () => context
                                  .read<CloudBackupCubit>()
                                  .downloadFile(file.name),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  _confirmDelete(context, file.name),
                            ),
                          ] else ...[
                            IconButton(
                              tooltip:
                                  transfer.status == CloudTransferStatus.paused
                                      ? 'Resume'
                                      : 'Pause',
                              icon: Icon(
                                transfer.status == CloudTransferStatus.paused
                                    ? Icons.play_arrow
                                    : Icons.pause,
                              ),
                              onPressed: () {
                                final cubit = context.read<CloudBackupCubit>();
                                if (transfer.status ==
                                    CloudTransferStatus.paused) {
                                  cubit.resumeTransfer(file.name);
                                } else {
                                  cubit.pauseTransfer(file.name);
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Cancel',
                              icon: const Icon(
                                Icons.close,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => context
                                  .read<CloudBackupCubit>()
                                  .cancelTransfer(file.name),
                            ),
                          ],
                        ],
                      ),
                      if (transfer != null) ...[
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: transfer.totalBytes == 0
                              ? null
                              : transfer.fraction,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${transfer.kind == CloudTransferKind.upload ? 'Uploading' : 'Downloading'}'
                          '${transfer.status == CloudTransferStatus.paused ? ' (paused)' : ''} '
                          '— ${(transfer.fraction * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
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
