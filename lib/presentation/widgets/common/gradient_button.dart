/// Gradient Button Widget
/// 
/// Reusable gradient button for check-in/out actions.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_colors.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final GradientType gradientType;

  const GradientButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.gradientType = GradientType.accent,
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> gradientColors = _getGradientColors();

    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: isDisabled || isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
          elevation: isDisabled ? 0 : 4,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 22.w),
                        SizedBox(width: 10.w),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    switch (gradientType) {
      case GradientType.accent:
        return [const Color(0xFFFF9500), const Color(0xFFFF6B00)];
      case GradientType.checkOut:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case GradientType.disabled:
        return [Colors.grey, Colors.grey.shade600];
      case GradientType.success:
        return [AppColors.success, const Color(0xFF16A34A)];
      case GradientType.primary:
        return [AppColors.primary, AppColors.primaryLight];
    }
  }
}

enum GradientType {
  accent,    // Orange - for check-in
  checkOut,  // Red - for check-out
  disabled,  // Gray - completed
  success,   // Green
  primary,   // Purple
}

/// Quick Action Card
class QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const QuickActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: color, size: 22.w),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textHint, size: 20.w),
            ],
          ),
        ),
      ),
    );
  }
}
