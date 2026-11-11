import 'package:flutter/material.dart';

class FieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final Widget? suffixIcon;
  final TextCapitalization textCapitalization;

  final VoidCallback? function;
  final String? Function(String?)? validator;

  const FieldWidget({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.none,
    this.function,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        onTap: function,
        readOnly: function != null,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: obscureText ? 1 : maxLines,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          errorText: errorText,
          errorMaxLines: 3,
          filled: true,
          suffixIcon:
              suffixIcon ??
              (function != null ? Icon(Icons.arrow_drop_down) : null),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
