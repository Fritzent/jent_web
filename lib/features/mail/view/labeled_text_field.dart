import 'package:flutter/material.dart';
import 'package:jent_web/core/theme/app_dimens.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppDimens.bodyFontSize,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: AppDimens.bodyFontSize),
            ),
          ),
        ],
      ),
    );
  }
}
