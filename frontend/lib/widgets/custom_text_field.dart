import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';

/// Clinical Enterprise Text Field using [ThemeColors] and standard design tokens.
class CustomTextField extends StatefulWidget {
  const CustomTextField({
    Key? key,
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
    this.maxLength,
    this.focusNode,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  }) : super(key: null);

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
  final int? maxLength;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _hovering = false;

  bool get _hasFocus => _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownsFocusNode = true;
      _focusNode = FocusNode();
    } else {
      _focusNode = widget.focusNode!;
    }
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  InputDecoration _decoration(BuildContext context) {
    final radius = AppRadius.borderMd;

    return InputDecoration(
      hintText: widget.hintText,
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ThemeColors.inputHint(context),
      ),
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      errorText: widget.errorText,
      counterText: '',
      filled: true,
      fillColor: _hasFocus
          ? ThemeColors.inputFocusFill(context)
          : _hovering
              ? ThemeColors.inputHoverFill(context)
              : ThemeColors.inputFill(context),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: ThemeColors.inputBorder(context),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: _hovering
              ? ThemeColors.inputHoverBorder(context)
              : ThemeColors.inputBorder(context),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: ThemeColors.inputFocus(context),
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: ThemeColors.error(context),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: ThemeColors.error(context),
          width: 1.8,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      key: widget.key,
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.autofillHints,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      cursorColor: ThemeColors.inputFocus(context),
      cursorWidth: 2,
      cursorRadius: const Radius.circular(2),
      textAlignVertical: TextAlignVertical.center,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ThemeColors.text(context),
      ),
      decoration: _decoration(context),
    );

    Widget content = MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.text,
      child: field,
    );

    if (widget.label == null) {
      return content;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label!,
          style: AppTypography.label(context),
        ),
        const SizedBox(height: 6),
        content,
      ],
    );
  }
}
