import 'package:flutter/material.dart';

class AestheticCustomKeyboard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onDone;

  const AestheticCustomKeyboard({
    super.key,
    required this.controller,
    required this.onDone,
  });

  void _handleKeyPress(String value) {
    final text = controller.text;

    if (value == '⌫') {
      if (text.isNotEmpty) {
        controller.text = text.substring(0, text.length - 1);
      }
    } else if (value == '-') {
      // Agar pehle se minus hai toh hatao, nahi toh lagao
      if (text.startsWith('-')) {
        controller.text = text.substring(1);
      } else if (text.startsWith('+')) {
        controller.text = '-${text.substring(1)}';
      } else {
        controller.text = '-$text';
      }
    } else if (value == '+') {
      // Agar pehle se plus hai toh hatao, nahi toh lagao
      if (text.startsWith('+')) {
        controller.text = text.substring(1);
      } else if (text.startsWith('-')) {
        controller.text = '+${text.substring(1)}';
      } else {
        controller.text = '+$text';
      }
    } else if (value == '.') {
      // Ek se zyada decimal allow nahi karna
      if (!text.contains('.')) {
        controller.text = text + value;
      }
    } else {
      controller.text = text + value;
    }

    // Cursor position hamesha end mein rakhein
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: mediaQuery.padding.bottom > 0 ? mediaQuery.padding.bottom : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF121212), // Sleek Dark Background
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Keyboard Top Bar (Done/Close Button)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onDone,
                icon: const Icon(
                  Icons.keyboard_hide_rounded,
                  size: 18,
                  color: Colors.blueAccent,
                ),
                label: const Text(
                  "Done",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Keypad Grid Layout
          Table(
            children: [
              TableRow(
                children: [
                  _buildKey('1'),
                  _buildKey('2'),
                  _buildKey('3'),
                  _buildSpecialKey(
                    '⌫',
                    Colors.redAccent.withOpacity(0.1),
                    Colors.redAccent,
                  ),
                ],
              ),
              TableRow(
                children: [
                  _buildKey('4'),
                  _buildKey('5'),
                  _buildKey('6'),
                  _buildSpecialKey(
                    '+',
                    Colors.amber.withOpacity(0.1),
                    Colors.amber.shade400,
                  ),
                ],
              ),
              TableRow(
                children: [
                  _buildKey('7'),
                  _buildKey('8'),
                  _buildKey('9'),
                  _buildSpecialKey(
                    '-',
                    Colors.amber.withOpacity(0.1),
                    Colors.amber.shade400,
                  ),
                ],
              ),
              TableRow(
                children: [
                  _buildKey('.'),
                  _buildKey('0'),
                  _buildKey('00'),
                  _buildSpecialKey(
                    '✓',
                    Colors.green.withOpacity(0.1),
                    Colors.greenAccent,
                    onPressed: onDone,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String value) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Material(
        color: const Color(0xFF1E1E1E), // Premium Charcoal Grey
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _handleKeyPress(value),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(
    String value,
    Color bg,
    Color textCol, {
    VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed ?? () => _handleKeyPress(value),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
