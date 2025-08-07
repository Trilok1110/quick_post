import 'package:flutter/material.dart';

class QPTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool autofocus;
  final List<String>? autofillHints;
  final void Function(String)? onChanged;
  final String? helperText;
  final String? errorText;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  const QPTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.autofocus = false,
    this.autofillHints,
    this.onChanged,
    this.helperText,
    this.errorText,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
  });

  @override
  State<QPTextField> createState() => _QPTextFieldState();
}

class _QPTextFieldState extends State<QPTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Optionally, you can listen for focus changes for even more complex UX.
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    double scale = MediaQuery.of(context).size.width >= 600 ? 1.1 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      curve: Curves.ease,
      decoration: BoxDecoration(
        boxShadow: _focusNode.hasFocus
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
        borderRadius: BorderRadius.circular(18),
      ),
      transform: Matrix4.identity()..scale(scale, scale),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        autofillHints: widget.autofillHints,
        autofocus: widget.autofocus,
        validator: widget.validator,
        focusNode: _focusNode,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        onChanged: widget.onChanged,
        textCapitalization: widget.textCapitalization,
        textInputAction: widget.textInputAction,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon, size: 22, color: _focusNode.hasFocus ? theme.colorScheme.primary : null),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: isDark ? theme.colorScheme.primary : theme.colorScheme.primary,
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.28),
              width: 1.1,
            ),
          ),
          filled: true,
          fillColor: _focusNode.hasFocus
              ? theme.colorScheme.primary.withOpacity(isDark ? 0.06 : 0.10)
              : theme.colorScheme.surfaceVariant.withOpacity(isDark ? 0.26 : 0.33),
          suffixIcon: widget.suffixIcon,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          helperText: widget.helperText,
          errorText: widget.errorText,
        ),
      ),
    );
  }
}

