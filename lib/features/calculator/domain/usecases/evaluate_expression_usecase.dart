/// Evaluates a basic 4-function infix expression with left-to-right
/// precedence (standard simple calculator behavior). Supports `+ - × ÷`
/// (and ASCII `* /`). Returns `null` on parse error or division by zero.
class EvaluateExpressionUseCase {
  String? call(String expression) {
    if (expression.isEmpty) return null;

    final normalized = expression.replaceAll('×', '*').replaceAll('÷', '/');

    final tokens = _tokenize(normalized);
    if (tokens == null || tokens.isEmpty) return null;

    // Strip trailing operator (user pressed = mid-entry)
    if (_isOperator(tokens.last)) tokens.removeLast();
    if (tokens.isEmpty) return null;

    double acc;
    try {
      acc = double.parse(tokens.first);
    } catch (_) {
      return null;
    }

    for (var i = 1; i < tokens.length; i += 2) {
      final op = tokens[i];
      if (i + 1 >= tokens.length) break;
      final rhs = double.tryParse(tokens[i + 1]);
      if (rhs == null) return null;

      switch (op) {
        case '+':
          acc += rhs;
        case '-':
          acc -= rhs;
        case '*':
          acc *= rhs;
        case '/':
          if (rhs == 0) return null;
          acc /= rhs;
        default:
          return null;
      }
    }

    return _format(acc);
  }

  List<String>? _tokenize(String expr) {
    final out = <String>[];
    final buf = StringBuffer();

    for (var i = 0; i < expr.length; i++) {
      final ch = expr[i];
      if (_isDigitOrDot(ch)) {
        buf.write(ch);
      } else if (_isOperator(ch)) {
        // Unary minus at start or after another operator
        if (ch == '-' && buf.isEmpty && (out.isEmpty || _isOperator(out.last))) {
          buf.write(ch);
          continue;
        }
        if (buf.isEmpty) return null;
        out.add(buf.toString());
        buf.clear();
        out.add(ch);
      } else {
        return null;
      }
    }
    if (buf.isNotEmpty) out.add(buf.toString());
    return out;
  }

  bool _isDigitOrDot(String c) =>
      (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39) || c == '.';

  bool _isOperator(String c) => c == '+' || c == '-' || c == '*' || c == '/';

  String _format(double v) {
    if (v.isNaN || v.isInfinite) return 'Error';
    if (v == v.truncateToDouble() && v.abs() < 1e16) {
      return v.toInt().toString();
    }
    var s = v.toStringAsFixed(8);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s;
  }
}
