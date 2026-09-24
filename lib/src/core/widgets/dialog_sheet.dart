import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Displays a modal bottom sheet with a custom widget.
///
/// The [showSizeSheet] function shows a modal bottom sheet with the specified widget.
/// It provides options to customize the background color, dismissibility, and margin of the sheet.
///
/// - [context]: The build context to show the bottom sheet.
/// - [widget]: The widget to be displayed inside the bottom sheet.
/// - [colors]: The background color of the bottom sheet. Defaults .
/// - [dismissible]: Determines whether the bottom sheet can be dismissed by tapping outside. Defaults to `true`.
/// - [edgeInsets]: The margin to be applied to the bottom sheet. Defaults to `EdgeInsets.zero`.
///
/// Returns a [Future] that completes when the bottom sheet is dismissed.
Future<void> showSizeSheet(
  BuildContext context,
  Widget widget, {
  Color? colors,
  bool dismissible = true,
  EdgeInsets? edgeInsets,
}) {
  return showModalBottomSheet<void>(
    isDismissible: dismissible,
    backgroundColor: colors ?? Colors.white,
    isScrollControlled: true,
    useSafeArea: true,
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return SingleChildScrollView(
            child: Container(
              margin: edgeInsets ?? EdgeInsets.zero,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: colors ?? Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Center(child: widget),
            ),
          );
        },
      );
    },
  );
}

Future<void> showDialogPop(
  BuildContext context,
  Widget widget, {
  Color? colors,
  bool dismissible = true,
  EdgeInsets? edgeInsets,
}) {
  return showAdaptiveDialog(
    barrierColor: Colors.black.withValues(alpha: 0.9),
    context: context,
    barrierDismissible: dismissible,
    builder: (BuildContext context) {
      return Material(
        type: MaterialType.transparency,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16).r,
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: colors ?? Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28).r,
                        child: widget,
                      ),
                      // Positioned(
                      //   top: 10,
                      //   right: 10,
                      //   child: GestureDetector(
                      //     onTap: $navigationService.back,
                      //     child: SvgPicture.asset(
                      //       AppImages.closeIcon,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

class DialogSheet {
  static void showCustom(
    BuildContext context, {
    required Widget child,
  }) {
    showSizeSheet(
      context,
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: child,
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    required String content,
    required String actionText,
    required VoidCallback onAction,
    Color? actionColor,
  }) {
    showDialogPop(
      context,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24).r,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAction();
                  },
                  child: Text(
                    actionText,
                    style: TextStyle(color: actionColor ?? Colors.blue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
