import 'package:cord_hearing/src/view/authentication/splash_view.dart';
import 'package:flutter/cupertino.dart';
// import 'package:cord_hearing/src/view/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toastification/toastification.dart';

// import 'package:solar_hatch_mobile/src/view/splash_view.dart';

class CordHearing extends StatelessWidget {
  const CordHearing({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: ScreenUtilInit(
        designSize: const Size(383, 852),
        minTextAdapt: true,
        splitScreenMode: true,

        builder: (BuildContext context, Widget? child) => MaterialApp(
          title: 'Cord hearing',
          debugShowCheckedModeBanner: false,
          home: const SplashView(),
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
        ),
      ),
    );
  }
}
