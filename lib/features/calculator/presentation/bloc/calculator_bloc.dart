import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/check_unlock_sequence_usecase.dart';
import '../../domain/usecases/evaluate_expression_usecase.dart';
import 'calculator_event.dart';
import 'calculator_state.dart';

class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  final EvaluateExpressionUseCase _evaluate;
  final CheckUnlockSequenceUseCase _checkUnlock;

  CalculatorBloc({
    required EvaluateExpressionUseCase evaluate,
    required CheckUnlockSequenceUseCase checkUnlock,
  })  : _evaluate = evaluate,
        _checkUnlock = checkUnlock,
        super(const CalculatorState.initial()) {
    on<CalculatorKeyPressed>(_onKeyPressed);
    on<CalculatorEqualsPressed>(_onEqualsPressed);
    on<CalculatorClearPressed>(_onClearPressed);
    on<CalculatorBackspacePressed>(_onBackspacePressed);
    on<CalculatorUnlockConsumed>((_, emit) {
      emit(state.copyWith(unlocked: false));
    });
  }

  static const _operators = {'+', '-', '×', '÷'};

  void _onKeyPressed(
    CalculatorKeyPressed event,
    Emitter<CalculatorState> emit,
  ) {
    final key = event.key;
    final history = [...state.keyHistory, key];
    String newDisplay;

    final isOp = _operators.contains(key);

    if (state.justEvaluated) {
      // Continue from result if operator pressed; reset if digit/dot
      if (isOp) {
        newDisplay = state.display + key;
      } else {
        newDisplay = key == '.' ? '0.' : key;
      }
    } else if (state.display == '0' && !isOp && key != '.') {
      newDisplay = key;
    } else if (state.display == 'Error') {
      newDisplay = isOp ? '0$key' : (key == '.' ? '0.' : key);
    } else {
      // Prevent two consecutive operators (replace the previous one)
      if (isOp &&
          state.display.isNotEmpty &&
          _operators.contains(state.display[state.display.length - 1])) {
        newDisplay = state.display.substring(0, state.display.length - 1) + key;
      } else if (key == '.' && _lastNumberHasDot(state.display)) {
        newDisplay = state.display;
      } else {
        newDisplay = state.display + key;
      }
    }

    emit(state.copyWith(
      display: newDisplay,
      keyHistory: history,
      justEvaluated: false,
    ));
  }

  void _onEqualsPressed(
    CalculatorEqualsPressed event,
    Emitter<CalculatorState> emit,
  ) {
    if (_checkUnlock(state.keyHistory)) {
      emit(state.copyWith(unlocked: true));
      return;
    }

    final result = _evaluate(state.display);
    emit(state.copyWith(
      display: result ?? 'Error',
      justEvaluated: true,
    ));
  }

  void _onClearPressed(
    CalculatorClearPressed event,
    Emitter<CalculatorState> emit,
  ) {
    emit(const CalculatorState.initial());
  }

  void _onBackspacePressed(
    CalculatorBackspacePressed event,
    Emitter<CalculatorState> emit,
  ) {
    if (state.justEvaluated || state.display == 'Error') {
      emit(const CalculatorState.initial());
      return;
    }
    if (state.display.length <= 1) {
      emit(state.copyWith(display: '0'));
      return;
    }
    final history = state.keyHistory.isEmpty
        ? state.keyHistory
        : state.keyHistory.sublist(0, state.keyHistory.length - 1);
    emit(state.copyWith(
      display: state.display.substring(0, state.display.length - 1),
      keyHistory: history,
    ));
  }

  bool _lastNumberHasDot(String s) {
    for (var i = s.length - 1; i >= 0; i--) {
      final c = s[i];
      if (_operators.contains(c)) return false;
      if (c == '.') return true;
    }
    return false;
  }
}
