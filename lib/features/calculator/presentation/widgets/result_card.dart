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
                  interpretation: result.frontFeetInterpretation,
                  isPositive: result.frontFeet >= 0,
                ),
                const Gap(12),
                _ResultRow(
                  label: 'Back Feet',
                  value: result.backFeetFormatted,
                  interpretation: result.backFeetInterpretation,
                  isPositive: result.backFeet >= 0,
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
        .slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final String interpretation;
  final bool isPositive;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.interpretation,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = value == '0.0000'
        ? cs.secondary
        : isPositive
        ? const Color(0xFF1B7A4A)
        : const Color(0xFFC0392B);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6, right: 10),
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
              const Gap(2),
              Row(
                children: [
                  Text(
                    '$value mm',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Text(
                interpretation,
                style: tt.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
