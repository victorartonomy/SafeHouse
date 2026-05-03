import 'package:equatable/equatable.dart';

class CalculatorExpression extends Equatable {
  final String display;
  final List<String> keyHistory;

  const CalculatorExpression({
    this.display = '0',
    this.keyHistory = const [],
  });

  CalculatorExpression copyWith({
    String? display,
    List<String>? keyHistory,
  }) {
    return CalculatorExpression(
      display: display ?? this.display,
      keyHistory: keyHistory ?? this.keyHistory,
    );
  }

  @override
  List<Object?> get props => [display, keyHistory];
}
