import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../domain/models/alignment_result.dart';

class ResultCard extends StatelessWidget {
  final AlignmentResult result;
  final String planeName;

  const ResultCard({super.key, required this.result, required this.planeName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: cs.primary,
                      size: 20,
                    ),
                    const Gap(8),
                    Text(
                      'Results — $planeName Plane',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                const Divider(height: 1),
                const Gap(16),
                _ResultRow(
                  label: 'Front Feet',
                  value: result.frontFeetForatted,
                  // Calculation value ko directly pass karein taaki color logic sahi chale
                  numericValue: result.frontFeet,
                  interpretation: result.frontFeetInterpretation,
                ),
                const Gap(12),
                _ResultRow(
                  label: 'Back Feet',
                  value: result.backFeetFormatted,
                  numericValue: result.backFeet,
                  interpretation: result.backFeetInterpretation,
                ),
                const Gap(16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: cs.onTertiaryContainer,
                      ),
                      const Gap(6),
                      Expanded(
                        child: Text(
                          '+ve = Add shim  •  −ve = Remove shim',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0, duration: 350.ms);
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final double numericValue;
  final String interpretation;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.numericValue,
    required this.interpretation,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Logic: 0 par blue/neutral, positive par Green, negative par Red
    final color = numericValue.abs() < 0.0001
        ? cs.secondary
        : (numericValue > 0
              ? const Color(0xFF1B7A4A)
              : const Color(0xFFC0392B));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 8, right: 10),
          decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    '$value mm',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.5,
                      // iOS web par negative sign font issue solve karne ke liye fontFeatures
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              Text(
                interpretation,
                style: tt.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
