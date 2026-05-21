import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

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

  // Minus (-) sign toggle karne ka function
  void _toggleMinus() {
    final text = controller.text;
    if (text.startsWith('-')) {
      controller.text = text.substring(1);
    } else {
      controller.text = '-$text';
    }
    // Cursor ko text ke last mein rakhne ke liye
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }

  // Next field par jaane ya keyboard band karne ka function
  void _handleSubmitted(BuildContext context) {
    if (nextFocusNode != null) {
      FocusScope.of(context).requestFocus(nextFocusNode);
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = !kIsWeb && Platform.isIOS;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          // iOS par hum wahi saaf-suthra number pad rakhenge jo aapki image mein hai
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),

          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
          ],

          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          onFieldSubmitted: (_) => _handleSubmitted(context),
          validator: validator,

          decoration: InputDecoration(
            labelText: label,
            hintText: hint ?? '0.00',
            suffixText: suffixText,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ),
        ),

        // Agar iOS device hai, toh keyboard ke theek upar ye choti minus aur done bar dikhegi
        if (isIOS && (focusNode?.hasFocus ?? false))
          Container(
            color: Colors
                .grey
                .shade900, // Aapke dark theme se match karta hua color
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Custom Minus Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  onPressed: _toggleMinus,
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text(
                    "Minus (-)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                // Done / Next Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _handleSubmitted(context),
                  child: Text(isLast ? "Done" : "Next"),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
