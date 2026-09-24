// ignore_for_file: inference_failure_on_function_return_type

import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A customizable text field widget for the application.
///
/// The [AppTextField] widget provides a flexible text input field that can be customized
/// with different properties and callbacks. It supports various use cases within the app.
class AppTextField extends StatefulWidget {
  /// Creates an [AppTextField] widget.
  ///
  /// The [hintText] parameter specifies the placeholder text to be displayed inside the text field.
  /// The [controller] parameter specifies the text editing controller for the text field.
  /// The [onChanged] callback is triggered when the text in the text field changes.
  /// The [onSaved] callback is triggered when the text field is saved.
  /// The [validator] parameter allows adding a validation function for the text field.
  /// The [enabled] parameter determines whether the text field is enabled.
  /// The [obscureText] parameter determines whether the text field should obscure the text.
  /// The [readOnly] parameter determines whether the text field is read-only.
  /// The [initialValue] parameter specifies the initial value of the text field.
  /// The [textInputAction] parameter specifies the action button to be displayed on the keyboard.
  /// The [textInputType] parameter specifies the type of keyboard to be used for text input.
  /// The [inputFormatters] parameter specifies the list of input formatters to be applied to the text field.
  /// The [floatHint] parameter determines whether the hint text should float above the text field.
  /// The [prefixWidget] parameter allows adding a widget before the text field.
  /// The [minLines] parameter specifies the minimum number of lines for the text field.
  /// The [maxLines] parameter specifies the maximum number of lines for the text field.
  /// The [suffixWidget] parameter allows adding a widget after the text field.
  /// The [onChanged] callback is triggered when the text in the text field changes.
  /// The [isPassword] parameter determines whether the text field is a password field.
  /// The [maxLength] parameter specifies the maximum length of the text field.
  /// The [onEditingComplete] callback is triggered when the text field editing is completed.
  /// The [filled] parameter determines whether the text field is filled.

  const AppTextField({
    this.isUnderlinedBorder = false,
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.enabled = true,
    this.obscureText = false,
    this.readOnly = false,
    this.initialValue,
    this.textInputAction = TextInputAction.next,
    this.textInputType,
    this.inputFormatters,
    this.floatHint = false,
    this.prefixWidget,
    this.minLines = 1,
    this.maxLines,
    this.onTap,
    this.suffixWidget,
    this.isPassword = false,
    this.maxLength,
    this.onEditingComplete,
    this.filled = true,
    this.textColor,
    this.title,
    this.titleColor,
    this.hasRequired,
    this.counterText,
    this.filledColor,
    this.focusNode,
    this.counter,
    this.fieldKey,
  });

  final Widget? counter;

  /// The placeholder text to be displayed inside the text field.
  final String? hintText;

  /// The text editing controller for the text field.
  final TextEditingController? controller;

  /// The callback that is triggered when the text in the text field changes.
  final void Function(String)? onChanged;

  /// The callback that is triggered when the text field is saved.
  final void Function(String?)? onSaved;

  /// A validation function for the text field.
  final String? Function(String?)? validator;

  /// Determines whether the text field is enabled.
  final bool enabled;

  /// Determines whether the text field should obscure the text.
  final bool obscureText;

  /// Determines whether the text field is read-only.
  final bool readOnly;

  /// The initial value of the text field.
  final String? initialValue;

  /// The action button to be displayed on the keyboard.
  final TextInputAction textInputAction;

  /// The type of keyboard to be used for text input.
  final TextInputType? textInputType;

  /// The list of input formatters to be applied to the text field.
  final List<TextInputFormatter>? inputFormatters;

  /// Determines whether the hint text should float above the text field.
  final bool floatHint;

  /// A widget to be displayed before the text field.
  final Widget? prefixWidget;

  /// The minimum number of lines for the text field.
  final int minLines;

  /// The title of the text field.
  final String? title;

  /// The callback that is triggered when the text field editing is completed.
  final Function()? onEditingComplete;

  /// Determines whether the text field is filled.
  final bool filled;

  /// The color of the text field.
  final Color? textColor;

  /// Determines whether the text field is a password field.
  final bool isPassword;

  /// A widget to be displayed after the text field.
  final Widget? suffixWidget;

  /// The maximum number of lines for the text field.
  final int? maxLines;

  /// The maximum length of the text field.
  final int? maxLength;

  /// The textstyle of the text field.
  final TextStyle? titleColor;

  /// Determines whether the text field is a requiredfield.
  final bool? hasRequired;
  final String? counterText;
  final Color? filledColor;
  final FocusNode? focusNode;

  /// The callback that is triggered when the text field is tapped.
  final Function()? onTap;
  final GlobalKey<FormFieldState<String>>? fieldKey;
  final bool isUnderlinedBorder;
  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _visible = true;
  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F600}-\u{1F64F}]|' // Emoticons
    r'[\u{1F300}-\u{1F5FF}]|' // Symbols & pictographs
    r'[\u{1F680}-\u{1F6FF}]|' // Transport & map
    r'[\u{1F1E6}-\u{1F1FF}]|' // Regional indicator (flags)
    r'[\u{2600}-\u{26FF}]|' // Misc symbols
    r'[\u{2700}-\u{27BF}]', // Dingbats
    unicode: true,
  );
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Row(
            children: [
              Text(
                widget.title!,
                style:
                    widget.titleColor ??
                    const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ],
          ),
          8.verticalSpace,
        ],
        TextFormField(
          key: widget.fieldKey,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: widget.textColor ?? Colors.black,

            fontWeight: FontWeight.w400,
            fontSize: 16.spMin,
          ),
          enableSuggestions: false,
          focusNode: widget.focusNode,
          controller: widget.controller,
          onChanged: widget.onChanged,
          validator: widget.validator,
          onSaved: widget.onSaved,
          onEditingComplete: widget.onEditingComplete,
          onTap: widget.onTap,
          cursorHeight: widget.isUnderlinedBorder ? 24 : null,
          maxLength: widget.maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          enabled: widget.enabled,
          obscureText: widget.isPassword ? _visible : !_visible,
          readOnly: widget.onTap != null || widget.readOnly,
          cursorColor: widget.textColor ?? AppColors.primaryColor,
          initialValue: widget.initialValue,
          keyboardType: widget.textInputType,

          textInputAction: widget.textInputAction,
          textCapitalization: TextCapitalization.sentences,

          inputFormatters: [
            FilteringTextInputFormatter.deny(
              _emojiRegex,
            ),
            ...(widget.inputFormatters ?? []),
          ],

          // widget.inputFormatters,
          minLines: widget.minLines,
          maxLines:
              // widget.obscureText
              (widget.maxLines != null
              ? widget.minLines > widget.maxLines!
                    ? widget.minLines
                    : widget.maxLines
              : (widget.isPassword ? 1 : null)),

          decoration: InputDecoration(
            counter: widget.counter,
            counterText: widget.counterText,
            filled: widget.filled,
            fillColor: widget.filledColor ?? Colors.white,
            prefixIcon: widget.prefixWidget == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 11, right: 11).r,
                    child: widget.prefixWidget,
                  ),
            suffixIcon:
                widget.suffixWidget ??
                (widget.isPassword
                    ? IconButton(
                        icon: _visible
                            ? const Icon(
                                Icons.visibility_off_rounded,
                                color: Color(0xFF334155),
                              )
                            : const Icon(
                                Icons.visibility_rounded,
                                color: Color(0xFF334155),
                              ),
                        onPressed: () {
                          setState(() {
                            _visible = !_visible;
                          });
                        },
                      )
                    : null),
            // fillColor:widget.isUnderlinedBorder?( widget.filledColor ?? AppColors.white),
            hintText: widget.hintText,
            enabled: widget.enabled,
            labelText: widget.floatHint ? widget.hintText : null,
            labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.grey,
              fontWeight: FontWeight.w600,
            ),
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.grey,

              fontWeight: FontWeight.w400,
              fontSize: 16.spMin,
            ),
            floatingLabelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.grey,
              fontSize: 12.spMin,
            ),
            errorMaxLines: 2,
            errorStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red,

              fontSize: 12.spMin,
            ),
            enabledBorder: enabledBorder,
            disabledBorder: disableBorder,
            focusedBorder: focusedBorder,
            focusedErrorBorder: focusedBorder,
            // border: widget.isUnderlinedBorder
            //     ? focusedBorderUnderlined
            //     : focusedBorder,
            errorBorder: focusedBorder,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 10,
            ).r,
          ),
        ),
      ],
    );
  }
}

final OutlineInputBorder enabledBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: const BorderSide(color: AppColors.grey),
);

final OutlineInputBorder focusedBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: const BorderSide(color: AppColors.primaryColor),
);

final OutlineInputBorder disableBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: const BorderSide(color: Colors.white),
);

final OutlineInputBorder disableBorderUnderlined = OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),

  borderSide: const BorderSide(color: AppColors.primaryColor),
);

// class UpperCaseTextFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(
//     TextEditingValue oldValue,
//     TextEditingValue newValue,
//   ) {
//     return TextEditingValue(
//       text: capitalize(newValue.text),
//       selection: newValue.selection,
//     );
//   }
// }

// String capitalize(String value) {
//   if (value.trim().isEmpty) return '';
//   return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
// }
