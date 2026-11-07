import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Labelled text input used by every form in the app.
class AppTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputAction? action;
  final TextCapitalization capitalization;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final String? optionalHint;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.obscure = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffix,
    this.action,
    this.capitalization = TextCapitalization.none,
    this.autofillHints,
    this.onSubmitted,
    this.optionalHint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, optionalHint: optionalHint),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscure,
          maxLines: maxLines,
          maxLength: maxLength,
          textInputAction: action,
          textCapitalization: capitalization,
          autofillHints: autofillHints,
          onFieldSubmitted: onSubmitted,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 20, color: AppColors.muted),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// Bold field label with an optional muted suffix such as "(optional)".
class FieldLabel extends StatelessWidget {
  final String text;
  final String? optionalHint;
  const FieldLabel(this.text, {super.key, this.optionalHint});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        children: [
          if (optionalHint != null)
            TextSpan(
              text: '  $optionalHint',
              style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5),
            ),
        ],
      ),
    );
  }
}
