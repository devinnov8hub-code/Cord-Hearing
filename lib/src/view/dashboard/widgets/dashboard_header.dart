import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:cord_hearing/src/view/profile/profile_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final displayName = email.isNotEmpty ? email.split('@').first : 'Guest';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text.rich(
          TextSpan(
            text: 'Hello, ',
            style: TextStyle(
              fontSize: 18.spMin,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
            children: [
              TextSpan(
                text: displayName,
                style: const TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const ProfileView(),
              ),
            );
          },
          child: const Icon(
            CupertinoIcons.person_alt_circle,
            size: 32,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }
}
