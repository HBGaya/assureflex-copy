import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/responsive_helper.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);
    final titleFontSize = ResponsiveHelper.getResponsiveFontSize(context, 28);
    final subtitleFontSize = ResponsiveHelper.getResponsiveFontSize(context, 16);

    return Column(
      children: [
    icon!=null?Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Icon(
            icon,
            size: 40,
            color: AppColors.primary,
          )):Image.asset('assets/logo.png',height: 80),
        SizedBox(height: responsivePadding),
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: AppColors.grey600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}