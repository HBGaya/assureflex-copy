import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CircleCheckbox extends StatelessWidget {
  const CircleCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 24,
    this.strokeWidth = 2.0,
    this.iconSize = 14,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;
  final double strokeWidth;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!, width: strokeWidth),
          // boxShadow: [
          //   // very soft shadow like in the figma card
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.04),
          //     blurRadius: 4,
          //     offset: const Offset(0, 1),
          //   ),
          // ],
        ),
        alignment: Alignment.center,
        child: AnimatedOpacity(
          opacity: value ? 1 : 0,
          duration: const Duration(milliseconds: 120),
          child: Icon(
            Icons.check_rounded,
            size: iconSize,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
