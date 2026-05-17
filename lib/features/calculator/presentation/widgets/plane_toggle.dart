import 'package:flutter/material.dart';

import '../../domain/models/alignment_input.dart';

class PlaneToggle extends StatelessWidget {
  final AlignmentPlane selectedPlane;
  final ValueChanged<AlignmentPlane> onChanged;

  const PlaneToggle({
    super.key,
    required this.selectedPlane,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _PlaneTab(
            label: '⬆ Vertical',
            isSelected: selectedPlane == AlignmentPlane.vertical,
            onTap: () => onChanged(AlignmentPlane.vertical),
          ),
          _PlaneTab(
            label: '➡ Horizontal',
            isSelected: selectedPlane == AlignmentPlane.horizontal,
            onTap: () => onChanged(AlignmentPlane.horizontal),
          ),
        ],
      ),
    );
  }
}

class _PlaneTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlaneTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? cs.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
