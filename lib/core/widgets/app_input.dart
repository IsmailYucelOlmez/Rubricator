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
    this.errorText,
    this.onEditingComplete,
    this.style,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;
  final Widget? prefixIcon;
  final String? errorText;
  final VoidCallback? onEditingComplete;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: style,
      obscureText: obscureText,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      onEditingComplete: onEditingComplete,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon,
        errorText: errorText,
      ),
    );
  }
}
