import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:flutter/material.dart';

/// A customizable loading indicator widget for the application.
///
/// The [AppLoading] widget provides a flexible loading indicator that can be customized
/// with different values and colors. It supports various use cases within the app.
class AppLoading extends StatelessWidget {
  /// Creates an [AppLoading] widget.
  ///
  /// The [value] parameter specifies the progress value of the loading indicator.
  /// If [value] is null, the indicator will display an indeterminate progress indicator.
  const AppLoading({super.key, this.value, this.color});

  /// The progress value of the loading indicator.
  final double? value;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: CircularProgressIndicator(
        color: color ?? AppColors.grey,
        value: value,
        strokeWidth: 2,
      ),
    );
  }
}
