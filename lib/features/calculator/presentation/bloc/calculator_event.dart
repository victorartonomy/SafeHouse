import 'package:equatable/equatable.dart';

abstract class CalculatorEvent extends Equatable {
  const CalculatorEvent();
  @override
  List<Object?> get props => [];
}

class CalculatorKeyPressed extends CalculatorEvent {
  final String key;
  const CalculatorKeyPressed(this.key);
  @override
  List<Object?> get props => [key];
}

class CalculatorEqualsPressed extends CalculatorEvent {
  const CalculatorEqualsPressed();
}

class CalculatorClearPressed extends CalculatorEvent {
  const CalculatorClearPressed();
}

class CalculatorBackspacePressed extends CalculatorEvent {
  const CalculatorBackspacePressed();
}

class CalculatorUnlockConsumed extends CalculatorEvent {
  const CalculatorUnlockConsumed();
}
