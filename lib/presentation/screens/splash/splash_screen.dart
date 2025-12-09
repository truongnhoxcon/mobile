import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/routes/app_router.dart';
import '../../blocs/blocs.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check auth state and navigate
    final authState = context.read<AuthBloc>().state;
    
    if (authState.status == AuthStatus.authenticated) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Handle auth state changes during splash
        if (state.status == AuthStatus.authenticated) {
          context.go(AppRoutes.home);
        } else if (state.status == AuthStatus.unauthenticated) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.business_center_rounded,
                  size: 60,
                  color: AppColors.primary,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(delay: 200.ms, duration: 400.ms),
              
              const SizedBox(height: 24),
              
              // App Name
              const Text(
                'Enterprise Mobile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),
              
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                'Quản lý dự án & Nhân sự',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 600.ms),
              
              const SizedBox(height: 48),
              
              // Loading indicator
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
