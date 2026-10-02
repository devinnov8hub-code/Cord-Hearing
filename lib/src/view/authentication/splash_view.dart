import 'package:cord_hearing/src/core/app_assets.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/view/authentication/onboarding_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToDashBoard();
    });
  }

  Future<void> _navigateToDashBoard() async {
    await Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute<void>(
          builder: (context) => const OnboardingView(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Stack(
        children: [
          SizedBox.expand(
            child: SvgPicture.asset(AppAssets.splashBg, fit: BoxFit.cover),
          ),
          Center(child: SvgPicture.asset(AppAssets.splashLogo)),
        ],
      ),
    );
  }
}
