import 'package:pump_alignment/features/calculator/domain/models/alignment_input.dart';
import 'package:pump_alignment/features/calculator/domain/models/alignment_result.dart';

class CalculatorService {
  const CalculatorService._();

  /// Rim & Face alignment calculation.
  /// Formula is the same for both planes — the plane label is
  /// purely a UI/context concern.
  ///
  /// Front Feet = (FaceTIR / A) × B + ½ × RimTIR
  /// Back Feet  = (FaceTIR / A) × (B + C) + ½ × RimTIR
  static AlignmentResult calculate(AlignmentInput input) {
    assert(input.a != 0, 'A (dial span) must not be zero');

    final faceComponent = input.faceTIR / input.a;
    final halfRim = 0.5 * input.rimTIR;

    final frontFeet = (faceComponent * input.b) + halfRim;
    final backFeet = (faceComponent * (input.b + input.c)) + halfRim;

    return AlignmentResult(frontFeet: frontFeet, backFeet: backFeet);
  }
}