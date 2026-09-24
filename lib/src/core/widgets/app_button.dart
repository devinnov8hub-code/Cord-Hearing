import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/core/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A customizable button widget for the application.
///
/// The [AppButton] widget provides a flexible button that can be customized
/// with different styles, colors, and icons. It supports both outlined and
/// filled styles, and can be used for various purposes within the app.
class AppButton extends StatelessWidget {
  /// Creates an [AppButton] widget.
  ///
  /// The [text] parameter is required and specifies the text to be displayed on the button.
  /// The [onPressed] callback is triggered when the button is pressed.
  /// The [width] and [height] parameters specify the dimensions of the button.
  /// The [isOutlined] parameter determines whether the button is outlined or filled.
  /// The [iconAlignment] parameter allows choosing the position of button icon.
  /// The [icon] parameter allows adding an icon to the button.
  /// The [isAuth] parameter specifies whether the button is used for authentication purposes.
  /// The [bgColor] and [textColor] parameters allow customizing the background and text colors.

  const AppButton({
    required this.text,
    super.key,
    this.onPressed,
    this.width = double.maxFinite,
    this.height = 49,
    this.isOutlined = false,
    this.iconAlignment = IconAlignment.end,
    this.icon,
    this.isAuth = false,
    this.bgColor = AppColors.primaryColor,
    this.textColor,
    this.isLoading = false,
    this.loadingColor,
    this.ignoreTextCapitalize = false,
    this.outlineColor = AppColors.grey,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius,
  });

  /// The callback that is triggered when the button is pressed.
  final void Function()? onPressed;

  /// The text to be displayed on the button.
  final String text;

  /// The width of the button.
  final double? width;

  final double? borderRadius;

  /// The height of the button.
  final double? height;

  /// Determines whether the button is outlined or filled.
  final bool isOutlined;

  /// A  value to determing the position of the icon on the button.
  final IconAlignment iconAlignment;

  /// An icon to be displayed on the button.
  final Widget? icon;

  /// Specifies whether the button is used for authentication purposes.
  final bool isAuth;

  final bool isLoading;

  /// The background color of the button.
  final Color? bgColor;
  final Color? loadingColor;

  /// The color of the button's outline when [isOutlined] is true.
  /// If not provided, it defaults to [AppColors.primaryColor].
  final Color? outlineColor;

  /// The text color of the button.
  final Color? textColor;

  /// ignores text capitalize
  final bool ignoreTextCapitalize;

  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height?.h,

      // decoration: BoxDecoration(boxShadow: [AppColors.appBoxShadow]),
      child: OutlinedButton.icon(
        onPressed: onPressed,

        style: OutlinedButton.styleFrom(
          padding: padding,
          shape: borderRadius != null
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius!),
                )
              : null,
          side: BorderSide(
            color: isOutlined
                ? outlineColor ?? AppColors.primaryColor
                : Colors.transparent,
          ),

          // shadowColor: const Color.fromARGB(255, 240, 240, 238),
          // elevation: 1,
          backgroundColor: onPressed != null
              ? (bgColor ??
                    (isOutlined ? AppColors.grey : bgColor ?? AppColors.grey))
              : const Color.fromRGBO(205, 187, 187, 0.5),
        ),
        iconAlignment: iconAlignment,
        icon: isLoading ? AppLoading(color: loadingColor) : icon,
        label: FittedBox(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.spMin,
              fontWeight: FontWeight.w600,
              color:
                  textColor ??
                  (isOutlined
                      ? outlineColor ?? AppColors.primaryColor
                      : Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
