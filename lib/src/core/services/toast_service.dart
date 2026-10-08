import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toastification/toastification.dart';

class Toasts {
  const Toasts._();

  static void showError(String text, {String? description}) => toastification
    ..dismissAll(delayForAnimation: false)
    ..show(
      alignment: Alignment.topCenter,
      style: ToastificationStyle.simple,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6).r,
      borderRadius: BorderRadius.circular(12),
      showIcon: true,

      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, color: Colors.red),
          4.horizontalSpace,
          Flexible(
            child: Text(
              description ?? text,
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: -0.16,
                color: Color.fromRGBO(19, 19, 19, 1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),

      // description: description == null
      //     ? null
      //     : Text(
      //         description,
      //         style: const TextStyle(
      //           color: Color.fromRGBO(17, 24, 39, 1),
      //           fontSize: 12,
      //         ),
      //       ),
      icon: const Icon(Icons.error, color: Colors.red),
      type: ToastificationType.error,

      closeButton: const ToastCloseButton(showType: CloseButtonShowType.none),
      autoCloseDuration: const Duration(seconds: 3),
    );

  static void showSuccess(String text, {String? description}) => toastification
    ..dismissAll()
    ..show(
      alignment: Alignment.topCenter,
      style: ToastificationStyle.simple,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6).r,
      borderRadius: BorderRadius.circular(12),
      showIcon: true,

      // borderSide: const BorderSide(color: Color.fromRGBO(22, 163, 74, 1)),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,

            color: Color.fromRGBO(22, 163, 74, 1),
          ),
          4.horizontalSpace,
          Flexible(
            child: Text(
              description ?? text,
              softWrap: true,
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: -0.16,
                color: Color.fromRGBO(19, 19, 19, 1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),

      icon: const Icon(
        Icons.check_circle_rounded,

        color: Color.fromRGBO(22, 163, 74, 1),
      ),
      type: ToastificationType.success,
      closeButton: const ToastCloseButton(showType: CloseButtonShowType.none),
      autoCloseDuration: const Duration(seconds: 3),
    );
}
