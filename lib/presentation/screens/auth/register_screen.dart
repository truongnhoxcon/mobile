import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/routes/app_router.dart';
import '../../blocs/blocs.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(AuthSignUpRequested(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    ));
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
              content: Text(state.errorMessage ?? 'Đăng ký thất bại'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tạo tài khoản',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  Text(
                    'Điền thông tin để đăng ký',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Name Field
                  CustomTextField(
                    controller: _nameController,
                    label: 'Họ và tên',
                    hint: 'Nhập họ và tên',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập họ tên';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 16.h),
                  
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
                  
                  SizedBox(height: 16.h),
                  
                  // Confirm Password Field
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Xác nhận mật khẩu',
                    hint: 'Nhập lại mật khẩu',
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword 
                            ? Icons.visibility_outlined 
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu';
                      }
                      if (value != _passwordController.text) {
                        return 'Mật khẩu không khớp';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Register Button with BlocBuilder
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return PrimaryButton(
                        text: 'Đăng ký',
                        isLoading: state.status == AuthStatus.loading,
                        onPressed: _handleRegister,
                      );
                    },
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đã có tài khoản? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14.sp,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          'Đăng nhập',
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
