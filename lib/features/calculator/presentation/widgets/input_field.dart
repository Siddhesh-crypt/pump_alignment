import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlignmentInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint; // Optional banaya (?)
  final String? suffixText;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final bool isLast;

  const AlignmentInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hint, // 'required' keyword hata diya
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
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
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
        hintText: hint ?? '0.00', // Agar hint pass nahi kiya toh default '0.00' dikhega
        suffixText: suffixText,
        suffixStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}