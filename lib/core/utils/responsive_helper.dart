import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

class ResponsiveHelper {
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  static bool isMediumScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 360 &&
        MediaQuery.of(context).size.width < 420;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 420;
  }

  static double getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return AppSizes.md;
    if (width < 420) return AppSizes.lg;
    return AppSizes.xl;
  }

  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseFontSize - 2;
    if (width < 420) return baseFontSize;
    return baseFontSize + 2;
  }
}