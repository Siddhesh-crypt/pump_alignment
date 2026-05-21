import 'package:flutter/material.dart';
import 'custom_keyboard.dart'; // Nayi file ko import karein

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

  void _openCustomKeyboard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black12, // Minimal background dimming
      builder: (context) {
        return AestheticCustomKeyboard(
          controller: controller,
          onDone: () {
            Navigator.pop(context); // Keyboard close karein
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
              // Automaticaly agla keyboard open karne ke liye delay
              Future.delayed(const Duration(milliseconds: 100), () {
                nextFocusNode!.requestFocus();
              });
            } else {
              FocusScope.of(context).unfocus();
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: true, // Yeh system keyboard ko aane se rokega
      onTap: () => _openCustomKeyboard(context),
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? '0.00',
        suffixText: suffixText,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
        // Ek dynamic cursor indicator jaisa look dene ke liye prefix icon
        prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
      ),
    );
  }
}
