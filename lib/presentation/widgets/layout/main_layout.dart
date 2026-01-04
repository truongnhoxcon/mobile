import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/blocs.dart';

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Check if user is PM, HR, or Admin - they have their own navigation in their home screens
        final isAdmin = authState.user?.isAdmin == true;
        final isPMorHR = authState.user?.isProjectManager == true || 
                         authState.user?.isHRManager == true;
        final isAtHomeTab = navigationShell.currentIndex == 0;
        
        // Hide MainLayout's bottom nav when Admin/PM/HR is at Home tab (they have their own nav)
        final shouldHideBottomNav = (isAdmin || isPMorHR) && isAtHomeTab;

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: shouldHideBottomNav 
            ? null 
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Trang chủ')),
                        Expanded(child: _buildNavItem(1, Icons.work_history_rounded, Icons.work_history_outlined, 'Công việc')),
                        Expanded(child: _buildNavItem(2, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chat')),
                        Expanded(child: _buildNavItem(3, Icons.fingerprint_rounded, Icons.fingerprint_outlined, 'Chấm công')),
                        Expanded(child: _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Cá nhân')),
                      ],
                    ),
                  ),
                ),
              ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, {int badge = 0}) {
    final isActive = navigationShell.currentIndex == index;
    
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : inactiveIcon,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                  size: 26.w,
                ),
                if (badge > 0)
                  Positioned(
                    right: -8.w,
                    top: -4.h,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
