// lib/widgets/enhanced_input_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

/// An enhanced input field widget with extensive customization options
///
/// This widget provides a consistent input experience with support for
/// various input types, validation, and visual customization.
class EnhancedInputField extends StatefulWidget {
  /// Controller for the text field
  final TextEditingController controller;

  /// Label text displayed above or within the field
  final String label;

  /// Optional hint text shown when the field is empty
  final String? hintText;

  /// Whether this field is for password entry (obscures text)
  final bool isPasswordField;

  /// The type of keyboard to use for editing the text
  final TextInputType keyboardType;

  /// Optional validation function
  final String? Function(String?)? validator;

  /// Optional helper text displayed below the field
  final String? helperText;

  /// Optional error text to display (overrides validation errors)
  final String? errorText;

  /// Whether the field is enabled
  final bool enabled;

  /// Optional prefix icon
  final IconData? prefixIcon;

  /// Optional suffix icon
  final IconData? suffixIcon;

  /// Custom action when suffix icon is tapped
  final VoidCallback? onSuffixIconTap;

  /// Maximum number of characters allowed
  final int? maxLength;

  /// Maximum number of lines for multiline input
  final int? maxLines;

  /// Minimum number of lines for multiline input
  final int minLines;

  /// Whether to auto-correct user input
  final bool autocorrect;

  /// Whether to auto-validate on each change
  final bool autovalidate;

  /// Whether to show a character counter
  final bool showCounter;

  /// Border radius for the field
  final double borderRadius;

  /// Optional input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Optional focus node
  final FocusNode? focusNode;

  /// Callback when text field is submitted
  final Function(String)? onSubmitted;

  /// Callback when text field changes
  final Function(String)? onChanged;

  /// Whether to auto-focus this field when screen loads
  final bool autofocus;

  /// Text alignment within the field
  final TextAlign textAlign;

  /// Text style for input text
  final TextStyle? textStyle;

  /// Whether to fill the field background
  final bool filled;

  /// Background color when filled is true
  final Color? fillColor;

  /// Border color in normal state
  final Color? borderColor;

  /// Border color when field is focused
  final Color? focusedBorderColor;

  /// Whether to show the label as floating
  final bool floatingLabel;

  /// Whether to enable text suggestions
  final bool enableSuggestions;

  /// Whether to show a clear button when text is entered
  final bool showClearButton;

  /// Animation duration for focus transitions
  final Duration animationDuration;

  const EnhancedInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.isPasswordField = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.maxLength,
    this.maxLines = 1,
    this.minLines = 1,
    this.autocorrect = true,
    this.autovalidate = false,
    this.showCounter = false,
    this.borderRadius = 8.0,
    this.inputFormatters,
    this.focusNode,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.textStyle,
    this.filled = false,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.floatingLabel = true,
    this.enableSuggestions = true,
    this.showClearButton = true,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<EnhancedInputField> createState() => _EnhancedInputFieldState();
}

class _EnhancedInputFieldState extends State<EnhancedInputField> {
  bool _obscureText = false;
  bool _hasError = false;
  String? _errorText;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPasswordField;
    _errorText = widget.errorText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(EnhancedInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.errorText != widget.errorText) {
      _errorText = widget.errorText;
      _hasError = widget.errorText != null;
    }

    if (oldWidget.focusNode != widget.focusNode && widget.focusNode != null) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode = widget.focusNode!;
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.floatingLabel) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
            child: Text(
              widget.label,
              style: TextStyles.bodyText.copyWith(
                fontWeight: FontWeight.w500,
                color: _getTextColor(),
              ),
            ),
          ),
        ],
        AnimatedContainer(
          duration: widget.animationDuration,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius + 4),
            boxShadow: _isFocused && !_hasError ? [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
              )
            ] : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: _obscureText,
            keyboardType: widget.keyboardType,
            validator: _validateInput,
            enabled: widget.enabled,
            maxLength: widget.maxLength,
            maxLines: widget.isPasswordField ? 1 : widget.maxLines,
            minLines: widget.minLines,
            autocorrect: widget.autocorrect,
            autovalidateMode: widget.autovalidate
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            inputFormatters: widget.inputFormatters,
            focusNode: _focusNode,
            onFieldSubmitted: widget.onSubmitted,
            onChanged: _handleOnChanged,
            autofocus: widget.autofocus,
            textAlign: widget.textAlign,
            style: widget.textStyle ?? TextStyles.bodyText,
            enableSuggestions: widget.enableSuggestions,
            decoration: _buildInputDecoration(),
          ),
        ),
      ],
    );
  }

  Color _getTextColor() {
    if (_hasError) return Colors.red;
    if (_isFocused) return AppColors.primaryColor;
    return Theme.of(context).colorScheme.onBackground;
  }

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      labelText: widget.floatingLabel ? widget.label : null,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: _errorText,
      counterText: widget.showCounter ? null : '',
      filled: widget.filled,
      fillColor: widget.fillColor ?? AppColors.backgroundColor.withOpacity(0.5),
      labelStyle: TextStyles.bodyText.copyWith(
        color: _getTextColor(),
      ),
      hintStyle: TextStyles.bodyText.copyWith(
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: BorderSide(
          color: widget.borderColor ?? AppColors.primaryColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: BorderSide(
          color: widget.borderColor ?? AppColors.primaryColor.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: BorderSide(
          color: widget.focusedBorderColor ?? AppColors.primaryColor,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: BorderSide(
          color: Colors.red,
          width: 2.0,
        ),
      ),
      prefixIcon: widget.prefixIcon != null
          ? Icon(
        widget.prefixIcon,
        color: _getTextColor(),
      )
          : null,
      suffixIcon: _buildSuffixIcon(),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 16.0,
      ),
      floatingLabelBehavior: widget.floatingLabel
          ? FloatingLabelBehavior.auto
          : FloatingLabelBehavior.never,
    );
  }

  Widget? _buildSuffixIcon() {
    // For password fields, show toggle visibility icon
    if (widget.isPasswordField) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: _getTextColor(),
          size: 22,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        splashRadius: 20,
      );
    }

    // For custom suffix icon
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          color: _getTextColor(),
        ),
        onPressed: widget.onSuffixIconTap,
        splashRadius: 20,
      );
    }

    // Clear button for non-empty fields
    if (widget.showClearButton && widget.controller.text.isNotEmpty) {
      return IconButton(
        icon: Icon(
          Icons.clear,
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          size: 20,
        ),
        onPressed: () {
          widget.controller.clear();
          if (widget.onChanged != null) {
            widget.onChanged!('');
          }
          setState(() {});
        },
        splashRadius: 20,
      );
    }

    return null;
  }

  String? _validateInput(String? value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      // Don't call setState during build phase
      _hasError = error != null;
      if (widget.errorText == null) {
        _errorText = error;
      }
      
      // Schedule a setState for after the build is complete
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
      
      return error;
    }
    return null;
  }

  void _handleOnChanged(String value) {
    if (widget.onChanged != null) {
      widget.onChanged!(value);
    }

    // Trigger validation if autovalidate is enabled
    if (widget.autovalidate) {
      // Call validator directly without setState
      final error = widget.validator?.call(value);
      _hasError = error != null;
      if (widget.errorText == null) {
        _errorText = error;
      }
    }

    // Schedule a setState for after the current frame
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }
}