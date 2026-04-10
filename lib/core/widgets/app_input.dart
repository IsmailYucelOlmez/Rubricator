import 'package:flutter/material.dart';

/// Text field that follows [ThemeData.inputDecorationTheme].
class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon,
      ),
    );
  }
}
