import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/routes/app_router.dart';
import '../../blocs/blocs.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(AuthSignInRequested(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    ));
  }

  void _handleGoogleSignIn() {
    context.read<AuthBloc>().add(AuthGoogleSignInRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go(AppRoutes.home);
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Đăng nhập thất bại'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 40.h),
                  
                  // Logo
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.business_center_rounded,
                      size: 40.w,
                      color: Colors.white,
                    ),
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  Text(
                    'Chào mừng trở lại!',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  Text(
                    'Đăng nhập để tiếp tục',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  
                  SizedBox(height: 40.h),
                  
                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Nhập email của bạn',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!value.contains('@')) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Mật khẩu',
                    hint: 'Nhập mật khẩu',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword 
                            ? Icons.visibility_outlined 
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to forgot password
                      },
                      child: Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Login Button with BlocBuilder
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return PrimaryButton(
                        text: 'Đăng nhập',
                        isLoading: state.status == AuthStatus.loading,
                        onPressed: _handleLogin,
                      );
                    },
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'hoặc',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Google Sign In Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return OutlinedButton.icon(
                        onPressed: state.status == AuthStatus.loading 
                            ? null 
                            : _handleGoogleSignIn,
                        icon: Icon(Icons.g_mobiledata, size: 24.w),
                        label: const Text('Đăng nhập với Google'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chưa có tài khoản? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14.sp,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.register),
                        child: Text(
                          'Đăng ký ngay',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
