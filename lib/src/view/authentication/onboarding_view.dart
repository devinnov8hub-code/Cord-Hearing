import 'package:cord_hearing/src/core/app_assets.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/core/widgets/app_button.dart';
import 'package:cord_hearing/src/core/widgets/onboarding_image_collage.dart';
import 'package:cord_hearing/src/view/authentication/create_account_view.dart';
import 'package:cord_hearing/src/view/authentication/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.35],
            colors: [Color(0xFFBCE3F9), Colors.white],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const Expanded(flex: 2, child: OnboardingImageCollage()),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20).r,
                  child: const _OnboardingContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
}

const List<_OnboardingData> _onboardingPages = [
  _OnboardingData(
    title: 'Chord Hearing Aid',
    subtitle:
        'Simple control for a better listening experience.\nPair your device, adjust settings, and stay\nconnected.',
  ),
  _OnboardingData(
    title: 'Personalized Sound',
    subtitle:
        'Your hearing, personalized. Manage your Cord\ndevice and fine-tune your experience from one\nsimple app.',
  ),
];

class _OnboardingContent extends StatefulWidget {
  const _OnboardingContent();

  @override
  State<_OnboardingContent> createState() => _OnboardingContentState();
}

class _OnboardingContentState extends State<_OnboardingContent> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        20.verticalSpace,
        Row(
          children: [
            SvgPicture.asset(
              AppAssets.logoIcon,
              height: 40.h,
              colorFilter: const ColorFilter.mode(
                AppColors.primaryColor,
                BlendMode.srcIn,
              ),
            ),
            16.horizontalSpace,
            Text(
              'Chord Hearing Aid',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24.spMin,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),

        SizedBox(
          height: MediaQuery.of(context).size.height * 0.12,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _onboardingPages.length,
            itemBuilder: (context, index) {
              final page = _onboardingPages[index];
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    page.subtitle,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 16.spMin,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF666666),
                      height: 1.5,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_onboardingPages.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              width: _currentIndex == index ? 48.w : 10.w,
              height: 10.h,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? AppColors.primaryColor
                    : const Color(0xFFD3D3D3),
                borderRadius: BorderRadius.circular(8.r),
              ),
            );
          }),
        ),
        Column(
          children: [
            AppButton(
              text: 'Create Account',
              borderRadius: 30.r,
              onPressed: () {
                Navigator.pushReplacement(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const CreateAccountView(),
                  ),
                );
              },
            ),
            16.verticalSpace,
            AppButton(
              text: 'Log In',
              isOutlined: true,
              outlineColor: Colors.transparent,
              bgColor: Colors.transparent,
              textColor: AppColors.primaryColor,
              onPressed: () {
                Navigator.pushReplacement(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const LoginView(),
                  ),
                );
              },
            ),
            24.verticalSpace,
          ],
        ),
      ],
    );
  }
}
