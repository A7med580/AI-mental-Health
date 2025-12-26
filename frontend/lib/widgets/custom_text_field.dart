import 'package:flutter/material.dart';

import '../app_colors.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.onChanged,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
  });

  final ValueChanged<String>? onChanged;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xffF2F2F2),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}