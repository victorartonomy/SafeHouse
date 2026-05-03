import 'package:flutter/material.dart';

enum CalcKeyKind { digit, operator, action, equals }

class CalcKey {
  final String label;
  final CalcKeyKind kind;
  const CalcKey(this.label, this.kind);
}

class CalculatorKeypad extends StatelessWidget {
  final void Function(CalcKey key) onKey;

  const CalculatorKeypad({super.key, required this.onKey});

  static const List<List<CalcKey>> _grid = [
    [
      CalcKey('C', CalcKeyKind.action),
      CalcKey('⌫', CalcKeyKind.action),
      CalcKey('÷', CalcKeyKind.operator),
      CalcKey('×', CalcKeyKind.operator),
    ],
    [
      CalcKey('7', CalcKeyKind.digit),
      CalcKey('8', CalcKeyKind.digit),
      CalcKey('9', CalcKeyKind.digit),
      CalcKey('-', CalcKeyKind.operator),
    ],
    [
      CalcKey('4', CalcKeyKind.digit),
      CalcKey('5', CalcKeyKind.digit),
      CalcKey('6', CalcKeyKind.digit),
      CalcKey('+', CalcKeyKind.operator),
    ],
    [
      CalcKey('1', CalcKeyKind.digit),
      CalcKey('2', CalcKeyKind.digit),
      CalcKey('3', CalcKeyKind.digit),
      CalcKey('=', CalcKeyKind.equals),
    ],
    [
      CalcKey('0', CalcKeyKind.digit),
      CalcKey('.', CalcKeyKind.digit),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final spacing = isWide ? 14.0 : 10.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in _grid)
              Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: Row(
                  children: [
                    for (var i = 0; i < row.length; i++) ...[
                      Expanded(
                        flex: row.length == 2 && i == 0 ? 2 : 1,
                        child: _KeyButton(
                          calcKey: row[i],
                          onTap: () => onKey(row[i]),
                          isWide: isWide,
                        ),
                      ),
                      if (i < row.length - 1) SizedBox(width: spacing),
                    ],
                    if (row.length == 2) ...[
                      SizedBox(width: spacing),
                      const Expanded(child: SizedBox()),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _KeyButton extends StatelessWidget {
  final CalcKey calcKey;
  final VoidCallback onTap;
  final bool isWide;

  const _KeyButton({
    required this.calcKey,
    required this.onTap,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final (bg, fg) = switch (calcKey.kind) {
      CalcKeyKind.equals => (cs.primary, cs.onPrimary),
      CalcKeyKind.operator => (cs.tertiaryContainer, cs.onTertiaryContainer),
      CalcKeyKind.action => (cs.secondaryContainer, cs.onSecondaryContainer),
      CalcKeyKind.digit => (cs.surfaceContainerHigh, cs.onSurface),
    };

    final fontSize = isWide ? 32.0 : 26.0;
    final height = isWide ? 80.0 : 64.0;

    return SizedBox(
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Text(
              calcKey.label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
