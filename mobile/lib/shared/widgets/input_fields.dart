import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';

/// Custom text input field with validation and animations
class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final Iterable<String>? autofillHints;
  final VoidCallback? onTap;
  
  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.inputFormatters,
    this.autofocus = false,
    this.autofillHints,
    this.onTap,
  });
  
  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (widget.onTap != null) {
      print('🔧 CustomTextField built with onTap callback');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyles.labelMedium.copyWith(
              color: isDark 
                  ? AppColors.darkTextSecondary 
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _isFocused = hasFocus;
            });
          },
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onTap: () {
              print('🔧 TextFormField onTap fired!');
              if (widget.onTap != null) {
                print('🔧 Calling widget.onTap callback');
                widget.onTap!();
              }
            },
            maxLines: widget.maxLines,
            enabled: widget.enabled,
            autofillHints: widget.autofillHints,
            inputFormatters: widget.inputFormatters,
            autofocus: widget.autofocus,
            style: TextStyles.bodyMedium.copyWith(
              color: isDark 
                  ? AppColors.darkTextPrimary 
                  : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? AppColors.primaryYellow
                          : (isDark 
                              ? AppColors.darkTextTertiary 
                              : AppColors.lightTextTertiary),
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
              filled: true,
              fillColor: isDark 
                  ? AppColors.darkSurface 
                  : AppColors.lightSurface,
            ),
          ),
        ),
      ],
    );
  }
}

/// Password input field with show/hide toggle
class PasswordField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  
  const PasswordField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
  });
  
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;
  
  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: widget.label,
      hint: widget.hint ?? 'Enter password',
      controller: widget.controller,
      obscureText: _obscureText,
      validator: widget.validator,
      onChanged: widget.onChanged,
      prefixIcon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}

/// Phone number input field with country code and autofill support
class PhoneField extends StatelessWidget {
  final String? label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enableAutofill;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  
  const PhoneField({
    super.key,
    this.label,
    this.controller,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.enableAutofill = true,
    this.onTap,
    this.suffixIcon,
  });
  
  @override
  Widget build(BuildContext context) {
    print('🔧 PhoneField build - onTap is ${onTap == null ? "NULL" : "NOT NULL"}');
    return CustomTextField(
      label: label ?? 'Phone Number',
      hint: 'Enter 10-digit mobile number',
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.phone,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      prefixIcon: Icons.phone_outlined,
      suffixIcon: suffixIcon,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      // Enable phone autofill hints
      autofillHints: enableAutofill ? [AutofillHints.telephoneNumber] : null,
    );
  }
}

/// Search field with clear button
class SearchField extends StatefulWidget {
  final String? hint;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final VoidCallback? onClear;
  
  const SearchField({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onClear,
  });
  
  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(() {
      setState(() {});
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: TextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: widget.hint ?? 'Search...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: isDark 
            ? AppColors.darkSurface 
            : AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusFull,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
}

/// Vehicle number input formatter for Indian registration numbers
/// Formats: MH31AB1234 -> MH 31 AB 1234
class VehicleNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all spaces and convert to uppercase
    String text = newValue.text.replaceAll(' ', '').toUpperCase();
    
    // Validate and restrict input based on position
    String validated = '';
    for (int i = 0; i < text.length && i < 10; i++) {
      final char = text[i];
      
      // Position 0-1: Must be letters (State code)
      if (i < 2) {
        if (RegExp(r'[A-Z]').hasMatch(char)) {
          validated += char;
        } else {
          // Invalid character for state code position, reject
          break;
        }
      }
      // Position 2-3: Must be numbers (District code)
      else if (i < 4) {
        if (RegExp(r'[0-9]').hasMatch(char)) {
          validated += char;
        } else {
          // Invalid character for district code position, reject
          break;
        }
      }
      // Position 4-5: Must be letters (Series code - 1 or 2 letters)
      else if (i < 6) {
        if (RegExp(r'[A-Z]').hasMatch(char)) {
          validated += char;
        } else if (i == 4 && RegExp(r'[0-9]').hasMatch(char)) {
          // If first letter position has number, we might have single letter format
          // Don't add it yet, but check next
          break;
        } else {
          break;
        }
      }
      // Position 6-9: Must be numbers (Unique number - 4 digits)
      else if (i < 10) {
        if (RegExp(r'[0-9]').hasMatch(char)) {
          validated += char;
        } else {
          // Invalid character for number position, reject
          break;
        }
      }
    }
    
    // Add spaces at appropriate positions for display
    String formatted = '';
    for (int i = 0; i < validated.length; i++) {
      if (i == 2 || i == 4) {
        formatted += ' ';
      } else if (i == 6 && validated.length > 6) {
        // Add space before the 4-digit number
        formatted += ' ';
      }
      formatted += validated[i];
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Vehicle number field with auto-formatting and validation
class VehicleNumberField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  
  const VehicleNumberField({
    super.key,
    this.controller,
    this.label,
    this.validator,
    this.onChanged,
  });

  @override
  State<VehicleNumberField> createState() => _VehicleNumberFieldState();
}

class _VehicleNumberFieldState extends State<VehicleNumberField> {
  late TextEditingController _controller;
  TextInputType _keyboardType = TextInputType.text;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_updateKeyboardType);
  }
  
  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_updateKeyboardType);
    }
    super.dispose();
  }
  
  void _updateKeyboardType() {
    final text = _controller.text.replaceAll(' ', '');
    final position = text.length;
    
    TextInputType newKeyboardType;
    
    // Position 0-1: Letters (State code)
    if (position < 2) {
      newKeyboardType = TextInputType.text;
    }
    // Position 2-3: Numbers (District code)
    else if (position < 4) {
      newKeyboardType = TextInputType.number;
    }
    // Position 4-5: Letters (Series code)
    else if (position < 6) {
      newKeyboardType = TextInputType.text;
    }
    // Position 6-9: Numbers (Unique number)
    else {
      newKeyboardType = TextInputType.number;
    }
    
    if (_keyboardType != newKeyboardType) {
      setState(() {
        _keyboardType = newKeyboardType;
      });
    }
  }
  
  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter vehicle number';
    }
    
    // Remove spaces for validation
    final cleanValue = value.replaceAll(' ', '');
    
    // Validate format: XX00XX0000 or XX00X0000
    final regex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$');
    if (!regex.hasMatch(cleanValue)) {
      return 'Enter valid vehicle number (e.g., MH 31 AB 1234)';
    }
    
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: _controller,
      label: widget.label ?? 'Vehicle Number *',
      hint: 'e.g., MH 31 AB 1234',
      prefixIcon: Icons.directions_car_outlined,
      keyboardType: _keyboardType,
      inputFormatters: [
        VehicleNumberFormatter(),
        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\s]')),
      ],
      validator: widget.validator ?? _defaultValidator,
      onChanged: widget.onChanged,
    );
  }
}
