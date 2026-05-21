import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlignmentInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? suffixText;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final bool isLast;

  const AlignmentInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.suffixText,
    this.validator,
    this.focusNode,
    this.nextFocusNode,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,

      // ── CRITICAL FIX FOR iOS WEB ──
      // 'text' keyboard type use karne se iOS Safari negative (-) sign dikhata hai.
      // Humne inputFormatter laga rakha hai jo sirf numbers aur '-' allow karega.
      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),

      inputFormatters: [
        // Sirf valid numbers aur negative sign allowed
        FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
      ],

      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? '0.00',
        suffixText: suffixText,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
    );
  }
}