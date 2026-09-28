import 'package:cord_hearing/src/core/app_assets.dart';
import 'package:cord_hearing/src/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingImageCollage extends StatelessWidget {
  const OnboardingImageCollage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8).r,
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24).r,
                    child: _ImageCard(imageUrl: AppAssets.onboardingGrid(1)),
                  ),
                ),
                4.horizontalSpace,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24).r,
                    child: _ImageCard(imageUrl: AppAssets.onboardingGrid(2)),
                  ),
                ),
                4.horizontalSpace,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12).r,
                    child: _ImageCard(imageUrl: AppAssets.onboardingGrid(3)),
                  ),
                ),
              ],
            ),
          ),
          4.verticalSpace,
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _ImageCard(imageUrl: AppAssets.onboardingGrid(4)),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Expanded(
                        child: _ImageCard(
                          imageUrl: AppAssets.onboardingGrid(5),
                        ),
                      ),
                      4.verticalSpace,
                      Expanded(
                        child: _ImageCard(
                          imageUrl: AppAssets.onboardingGrid(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32.r),
        color: AppColors.grey.withValues(alpha: 0.2),
        image: DecorationImage(image: AssetImage(imageUrl), fit: BoxFit.cover),
      ),
    );
  }
}
