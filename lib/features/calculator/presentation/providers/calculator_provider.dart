import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/calculator_service.dart';
import '../../domain/models/alignment_input.dart';
import '../../domain/models/alignment_result.dart';


class CalculatorState {
  final AlignmentPlane plane;
  final AlignmentResult? result;
  final String? errorMessage;

  const CalculatorState({
    this.plane = AlignmentPlane.vertical,
    this.result,
    this.errorMessage,
  });

  CalculatorState copyWith({
    AlignmentPlane? plane,
    AlignmentResult? result,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return CalculatorState(
      plane: plane ?? this.plane,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CalculatorNotifier extends StateNotifier<CalculatorState> {
  CalculatorNotifier() : super(const CalculatorState());

  void setPlane(AlignmentPlane plane) {
    state = state.copyWith(plane: plane, clearResult: true);
  }

  void calculate({
    required double a,
    required double b,
    required double c,
    required double faceTIR,
    required double rimTIR,
  }) {
    try {
      final input = AlignmentInput(
        a: a,
        b: b,
        c: c,
        faceTIR: faceTIR,
        rimTIR: rimTIR,
        plane: state.plane,
      );
      final result = CalculatorService.calculate(input);
      state = state.copyWith(result: result, clearError: true);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Calculation error: $e',
        clearResult: true,
      );
    }
  }

  void reset() {
    state = const CalculatorState();
  }
}

final calculatorProvider =
StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
  return CalculatorNotifier();
});