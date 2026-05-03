import 'package:flutter/material.dart';

class CalculatorDisplay extends StatelessWidget {
  final String value;

  const CalculatorDisplay({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: FittedBox(
        alignment: Alignment.centerRight,
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          maxLines: 1,
          textAlign: TextAlign.right,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w300,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
