import 'package:cord_hearing/src/controller/login_view_controller.dart';
import 'package:cord_hearing/src/core/app_assets.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/core/widgets/app_button.dart';
import 'package:cord_hearing/src/core/widgets/app_textfield.dart';
import 'package:cord_hearing/src/core/widgets/onboarding_image_collage.dart';
import 'package:cord_hearing/src/view/authentication/create_account_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
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
                  flex: 3,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ).r,
                              child: const _LoginContent(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginContent extends ConsumerStatefulWidget {
  const _LoginContent();

  @override
  ConsumerState<_LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends ConsumerState<_LoginContent> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    final success = await ref.read(loginViewControllerProvider.notifier).login(email, password);

    if (!success && mounted) {
      final error = ref.read(loginViewControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? 'Login failed')),
      );
    } else if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful')),
      );
      // Navigate to Dashboard or home here if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewControllerProvider);
    final isLoading = loginState.isLoading;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  AppAssets.logoIcon,
                  height: 36.h,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryColor,
                    BlendMode.srcIn,
                  ),
                ),
                12.horizontalSpace,
                Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 24.spMin,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            16.verticalSpace,
            Text(
              'Enter your email and password to\nsign in to your Cord account.',
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
        ),
        Column(
          children: [
            AppTextField(
              controller: _emailController,
              title: 'Enter your email',
              hintText: 'e.g User@Gmail.com',
              prefixWidget: const Icon(Icons.mail_outline_rounded, color: Colors.grey),
              textInputType: TextInputType.emailAddress,
            ),
            16.verticalSpace,
            AppTextField(
              controller: _passwordController,
              title: 'Enter your password',
              hintText: '********',
              prefixWidget: const Icon(Icons.lock_outline_rounded, color: Colors.grey),
              textInputType: TextInputType.visiblePassword,
              isPassword: true,
            ),
          ],
        ),
        Column(
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else
              AppButton(
                text: 'Continue',
                onPressed: _login,
              ),
            24.verticalSpace,
            RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(
                  color: const Color(0xFF666666),
                  fontSize: 14.spMin,
                ),
                children: [
                  TextSpan(
                    text: 'Sign Up',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14.spMin,
                      fontWeight: FontWeight.w500,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const CreateAccountView(),
                          ),
                        );
                      },
                  ),
                ],
              ),
            ),
            24.verticalSpace,
          ],
        ),
      ],
    );
  }
}
