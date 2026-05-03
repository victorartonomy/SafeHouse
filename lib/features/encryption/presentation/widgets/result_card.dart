import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Inline card shown after a successful or failed operation.
class ResultCard extends StatelessWidget {
  final bool isSuccess;
  final String title;
  final String? subtitle;
  final String? copyableValue;
  final String? copyLabel;
  final VoidCallback? onDismiss;

  const ResultCard({
    super.key,
    required this.isSuccess,
    required this.title,
    this.subtitle,
    this.copyableValue,
    this.copyLabel,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSuccess
        ? theme.colorScheme.primary
        : const Color(0xFFFF4D4D);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
              ),
              if (onDismiss != null)
                InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: color),
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
          if (copyableValue != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      copyableValue!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: copyableValue!),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${copyLabel ?? 'Value'} copied to clipboard',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Icon(Icons.copy_outlined, size: 15, color: color),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
