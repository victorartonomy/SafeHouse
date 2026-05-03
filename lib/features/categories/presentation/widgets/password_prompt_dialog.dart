import 'package:flutter/material.dart';

/// Modal dialog asking for a category password.
///
/// Returns the entered password (trimmed) or `null` if cancelled.
/// Password is never persisted; caller derives the AES key in-memory.
class PasswordPromptDialog extends StatefulWidget {
  final String categoryName;
  final String title;
  final String confirmLabel;

  const PasswordPromptDialog({
    super.key,
    required this.categoryName,
    this.title = 'Enter password',
    this.confirmLabel = 'Continue',
  });

  /// Convenience launcher.
  static Future<String?> show(
    BuildContext context, {
    required String categoryName,
    String title = 'Enter password',
    String confirmLabel = 'Continue',
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PasswordPromptDialog(
        categoryName: categoryName,
        title: title,
        confirmLabel: confirmLabel,
      ),
    );
  }

  @override
  State<PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<PasswordPromptDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    // Best-effort wipe of in-memory password.
    _controller.text = '';
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category: ${widget.categoryName}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: _obscure,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
