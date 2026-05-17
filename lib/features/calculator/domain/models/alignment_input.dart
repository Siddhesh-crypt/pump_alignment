enum AlignmentPlane {vertical, horizontal}

class AlignmentInput {
  final double a;
  final double b;
  final double c;
  final double faceTIR;
  final double rimTIR;
  final AlignmentPlane plane;

  const AlignmentInput({
    required this.a,
    required this.b,
    required this.c,
    required this.faceTIR,
    required this.rimTIR,
    required this.plane,
  });
}