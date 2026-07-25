import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Themed text field using [AppTheme.inputDecorationTheme] via [Theme.of(context)].
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.label,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.errorText,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.inputFormatters,
    this.focusNode,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? minLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  InputDecoration _decoration(BuildContext context) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,
    ).applyDefaults(Theme.of(context).inputDecorationTheme);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: _decoration(context),
    );

    if (label == null) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 10),
        field,
      ],
    );
  }
}
