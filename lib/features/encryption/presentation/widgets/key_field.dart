import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A text field for AES secret key input.
///
/// Features:
/// - Show / hide key toggle (eye icon)
/// - Copy to clipboard button
/// - Optional "Generate Key" button
/// - Character count indicator
class KeyField extends StatefulWidget {
  final TextEditingController controller;
  final bool showGenerateButton;
  final VoidCallback? onGenerate;
  final String label;
  final String hint;

  const KeyField({
    super.key,
    required this.controller,
    this.showGenerateButton = false,
    this.onGenerate,
    this.label = 'Secret Key',
    this.hint = 'Paste or generate an AES-256 key',
  });

  @override
  State<KeyField> createState() => _KeyFieldState();
}

class _KeyFieldState extends State<KeyField> {
  bool _obscured = true;

  void _toggleObscure() => setState(() => _obscured = !_obscured);

  Future<void> _copyToClipboard() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Key copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.surface,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: _obscured,
          // Prevent the on-device keyboard from learning / suggesting the
          // AES key. Critical: a typed key would otherwise be added to the
          // user's personal dictionary and surface elsewhere.
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const <String>[],
          keyboardType: TextInputType.visiblePassword,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontFamily: 'monospace',
            fontSize: 13,
            letterSpacing: 0.5,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Eye toggle
                _IconBtn(
                  icon: _obscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  tooltip: _obscured ? 'Show key' : 'Hide key',
                  onTap: _toggleObscure,
                ),
                // Copy
                _IconBtn(
                  icon: Icons.copy_outlined,
                  tooltip: 'Copy key',
                  onTap: _copyToClipboard,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          maxLines: 1,
        ),
        // Generate button (optional)
        if (widget.showGenerateButton) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onGenerate,
              icon: Icon(Icons.refresh, size: 16, color: accent),
              label: Text(
                'Generate Random Key',
                style: TextStyle(color: accent, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accent.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}
