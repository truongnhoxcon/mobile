import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/routes/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<User?>? _authSubscription;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    // Wait for splash animation
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted || _hasNavigated) return;

    // Check if user is already signed in
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      // User session restored from persistence
      _navigateTo(AppRoutes.home);
      return;
    }

    // Wait for Firebase to restore session (it might take a moment)
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (_hasNavigated) return;
      
      if (user != null) {
        _navigateTo(AppRoutes.home);
      }
    });

    // Give Firebase some time to restore session
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted || _hasNavigated) return;

    // If still no user after waiting, go to login
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _navigateTo(AppRoutes.home);
    } else {
      _navigateTo(AppRoutes.login);
    }
  }

  void _navigateTo(String route) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
    );
  }
}
