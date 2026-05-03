import 'package:equatable/equatable.dart';

class CalculatorState extends Equatable {
  final String display;
  final List<String> keyHistory;
  final bool justEvaluated;
  final bool unlocked;

  const CalculatorState({
    this.display = '0',
    this.keyHistory = const [],
    this.justEvaluated = false,
    this.unlocked = false,
  });

  const CalculatorState.initial() : this();

  CalculatorState copyWith({
    String? display,
    List<String>? keyHistory,
    bool? justEvaluated,
    bool? unlocked,
  }) {
    return CalculatorState(
      display: display ?? this.display,
      keyHistory: keyHistory ?? this.keyHistory,
      justEvaluated: justEvaluated ?? this.justEvaluated,
      unlocked: unlocked ?? this.unlocked,
    );
  }

  @override
  List<Object?> get props => [display, keyHistory, justEvaluated, unlocked];
}
