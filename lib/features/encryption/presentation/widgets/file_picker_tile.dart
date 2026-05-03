import 'package:flutter/material.dart';

/// Displays the currently picked file (or a "no file" placeholder) and
/// exposes a [onTap] callback so the parent can trigger the file picker.
class FilePickerTile extends StatelessWidget {
  final String? fileName;
  final String? filePath;
  final VoidCallback onTap;
  final String label;

  const FilePickerTile({
    super.key,
    required this.onTap,
    this.fileName,
    this.filePath,
    this.label = 'Pick a file',
  });

  bool get _hasFile => fileName != null && fileName!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final outline = theme.colorScheme.outline;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hasFile ? accent.withValues(alpha: 0.6) : outline,
            width: _hasFile ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _hasFile
                    ? accent.withValues(alpha: 0.12)
                    : outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _hasFile ? Icons.insert_drive_file_outlined : Icons.upload_file,
                color: _hasFile ? accent : theme.iconTheme.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: _hasFile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName!,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'File selected — tap to change',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to browse',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
            ),
            // Trailing icon
            Icon(
              _hasFile ? Icons.check_circle_outline : Icons.chevron_right,
              color: _hasFile ? accent : theme.iconTheme.color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
