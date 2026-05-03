/// Detects unlock sequence "158+-=".
///
/// Caller maintains a rolling list of keypresses (digits + operators only —
/// `=` triggers the check, it is not in the buffer). Returns `true` when the
/// last 5 entries are `1, 5, 8, +, -` at the moment `=` is pressed.
class CheckUnlockSequenceUseCase {
  static const List<String> _expected = ['1', '5', '8', '+', '-'];

  bool call(List<String> keyHistory) {
    if (keyHistory.length < _expected.length) return false;
    final tail = keyHistory.sublist(keyHistory.length - _expected.length);
    for (var i = 0; i < _expected.length; i++) {
      if (tail[i] != _expected[i]) return false;
    }
    return true;
  }
}
