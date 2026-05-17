class AlignmentResult {
  final double frontFeet;
  final double backFeet;

  const AlignmentResult({
    required this.frontFeet,
    required this.backFeet,
  });

  String interpretValue(double value) {
    if (value > 0) return 'ADD ${value.abs().toStringAsFixed(4)} mm shim';
    if (value < 0) return 'REMOVE ${value.abs().toStringAsFixed(4)} mm shim';
    return 'No correction needed';
  }

  String get frontFeetForatted => frontFeet.toStringAsFixed(4);
  String get backFeetFormatted => backFeet.toStringAsFixed(4);
  String get frontFeetInterpretation => interpretValue(frontFeet);
  String get backFeetInterpretation => interpretValue(backFeet);
}