import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:pump_alignment/core/utils/validators.dart';
import 'package:pump_alignment/features/calculator/domain/models/alignment_input.dart';
import 'package:pump_alignment/features/calculator/presentation/providers/calculator_provider.dart';
import 'package:pump_alignment/features/calculator/presentation/widgets/input_field.dart';
import 'package:pump_alignment/features/calculator/presentation/widgets/plane_toggle.dart';
import 'package:pump_alignment/features/calculator/presentation/widgets/result_card.dart';
import 'package:pump_alignment/features/licensing/presentation/providers/licensing_provider.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _aCtrl = TextEditingController();
  final _bCtrl = TextEditingController();
  final _cCtrl = TextEditingController();
  final _faceCtrl = TextEditingController();
  final _rimCtrl = TextEditingController();

  final _aFocus = FocusNode();
  final _bFocus = FocusNode();
  final _cFocus = FocusNode();
  final _faceFocus = FocusNode();
  final _rimFocus = FocusNode();

  bool _isCalculating = false;

  @override
  void dispose() {
    for (final c in [_aCtrl, _bCtrl, _cCtrl, _faceCtrl, _rimCtrl]) c.dispose();
    for (final f in [_aFocus, _bFocus, _cFocus, _faceFocus, _rimFocus])
      f.dispose();
    super.dispose();
  }

  void _runCalculation() {
    ref
        .read(calculatorProvider.notifier)
        .calculate(
          a: double.parse(_aCtrl.text.trim()),
          b: double.parse(_bCtrl.text.trim()),
          c: double.parse(_cCtrl.text.trim()),
          faceTIR: double.parse(_faceCtrl.text.trim()),
          rimTIR: double.parse(_rimCtrl.text.trim()),
        );
  }

  Future<void> _onCalculatePressed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCalculating = true);

    try {
      final allowed = await ref
          .read(licensingProvider.notifier)
          .consumeTrialAndCheck();
      if (!mounted) return;
      if (allowed) _runCalculation();
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  void _reset() {
    _formKey.currentState?.reset();
    for (final c in [_aCtrl, _bCtrl, _cCtrl, _faceCtrl, _rimCtrl]) c.clear();
    ref.read(calculatorProvider.notifier).reset();
    FocusScope.of(context).unfocus();
  }

  Widget _buildTrialBadge(LicensingState licState) {
    if (licState.isPremium) {
      return const Padding(
        padding: EdgeInsets.only(right: 8),
        child: Icon(Icons.workspace_premium_rounded, color: Colors.amber),
      );
    }
    final count = licState.trialCount;
    final isLow = count <= 2;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Chip(
        visualDensity: VisualDensity.compact,
        backgroundColor: isLow
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        label: Text(
          '$count left',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isLow
                ? Theme.of(context).colorScheme.onErrorContainer
                : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calcState = ref.watch(calculatorProvider);
    final licState = ref.watch(licensingProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final planeName = calcState.plane == AlignmentPlane.vertical
        ? 'Vertical'
        : 'Horizontal';

    // ── NEW: Listen for Expiry Warnings and show a Snackbar ──
    ref.listen<LicensingState>(licensingProvider, (previous, next) {
      if (next.warningMessage != null &&
          next.warningMessage != previous?.warningMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white),
                const Gap(12),
                Expanded(
                  child: Text(
                    next.warningMessage!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade800, // Warning color
            duration: const Duration(seconds: 10), // Will stay for 10 seconds
          ),
        );
      }
    });

    return GestureDetector(
      // iOS Tap-to-dismiss keyboard wrapper
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shaft Alignment',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'Rim & Face Calculator',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            _buildTrialBadge(licState),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Clear',
              onPressed: _reset,
            ),
            const Gap(4),
          ],
        ),
        body: SafeArea(
          bottom: true, // iOS Bottom Swipe bar avoidance
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(), // iOS native scroll feel
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PlaneToggle(
                    selectedPlane: calcState.plane,
                    onChanged: (p) =>
                        ref.read(calculatorProvider.notifier).setPlane(p),
                  ),
                  const Gap(16),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(20),
                          height: 200,
                          width: double.infinity,
                          child: Image.asset(
                            'assets/images/pump_alignment_diagram.jpg',
                            fit: BoxFit.contain,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: cs.surfaceContainerLow,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Physical Dimensions',
                                style: tt.labelLarge?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Gap(12),
                              AlignmentInputField(
                                controller: _aCtrl,
                                focusNode: _aFocus,
                                nextFocusNode: _bFocus,
                                label: 'Value of A in mm',
                                suffixText: 'mm',
                                validator: (v) =>
                                    Validators.nonZeroDouble(v, 'A'),
                              ),
                              const Gap(12),
                              AlignmentInputField(
                                controller: _bCtrl,
                                focusNode: _bFocus,
                                nextFocusNode: _cFocus,
                                label: 'Value of B in mm',
                                suffixText: 'mm',
                                validator: (v) =>
                                    Validators.requiredDouble(v, 'B'),
                              ),
                              const Gap(12),
                              AlignmentInputField(
                                controller: _cCtrl,
                                focusNode: _cFocus,
                                nextFocusNode: _faceFocus,
                                label: 'Value of C in mm',
                                suffixText: 'mm',
                                validator: (v) =>
                                    Validators.requiredDouble(v, 'C'),
                              ),
                              const Gap(24),
                              Divider(color: cs.outlineVariant),
                              const Gap(12),
                              Text(
                                '$planeName TIR Readings',
                                style: tt.labelLarge?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Gap(12),
                              Row(
                                children: [
                                  Expanded(
                                    child: AlignmentInputField(
                                      controller: _faceCtrl,
                                      focusNode: _faceFocus,
                                      nextFocusNode: _rimFocus,
                                      label: 'Face TIR in mm',
                                      suffixText: 'mm',
                                      validator: (v) =>
                                          Validators.requiredDouble(
                                            v,
                                            'Face TIR',
                                          ),
                                    ),
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: AlignmentInputField(
                                      controller: _rimCtrl,
                                      focusNode: _rimFocus,
                                      label: 'Rim TIR in mm',
                                      suffixText: 'mm',
                                      isLast: true,
                                      validator: (v) =>
                                          Validators.requiredDouble(
                                            v,
                                            'Rim TIR',
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  // _FormulaReference(plane: planeName),
                  const Gap(24),
                  ElevatedButton.icon(
                    onPressed: _isCalculating ? null : _onCalculatePressed,
                    icon: _isCalculating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.calculate_rounded),
                    label: Text(
                      _isCalculating ? 'Processing...' : 'Calculate Correction',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Gap(16),
                  if (calcState.result != null)
                    ResultCard(result: calcState.result!, planeName: planeName),
                  if (calcState.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        calcState.errorMessage!,
                        style: TextStyle(
                          color: cs.error,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const Gap(40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormulaReference extends StatelessWidget {
  final String plane;
  const _FormulaReference({required this.plane});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: cs.primary),
              const Gap(8),
              Text(
                '$plane Plane Strategy',
                style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Gap(12),
          _FormulaLine(
            label: 'Front Correction',
            formula: '(FaceTIR ÷ A) × B + ½ × RimTIR',
          ),
          const Gap(6),
          _FormulaLine(
            label: 'Rear Correction',
            formula: '(FaceTIR ÷ A) × (B + C) + ½ × RimTIR',
          ),
        ],
      ),
    );
  }
}

class _FormulaLine extends StatelessWidget {
  final String label;
  final String formula;
  const _FormulaLine({required this.label, required this.formula});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Expanded(
          child: Text(
            formula,
            style: TextStyle(
              fontFamily: 'monospace',
              color: cs.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
