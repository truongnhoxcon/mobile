import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/blocs/blocs.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/projects/project_list_screen.dart';
import '../../presentation/screens/projects/project_detail_screen.dart';
import '../../presentation/screens/hr/hr_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';

/// App Route Names
class AppRoutes {
  AppRoutes._();
  
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String projects = '/projects';
  static const String projectDetail = '/projects/:id';
  static const String hr = '/hr';
  static const String attendance = '/hr/attendance';
  static const String leave = '/hr/leave';
  static const String salary = '/hr/salary';
  static const String chat = '/chat';
  static const String chatRoom = '/chat/:roomId';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
}

/// App Router
class AppRouter {
  AppRouter._();

  static GoRouter router(BuildContext context) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: true,
      
      // Redirect based on auth state
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final isAuthenticated = authState.status == AuthStatus.authenticated;
        final isAuthRoute = state.matchedLocation == AppRoutes.login ||
            state.matchedLocation == AppRoutes.register ||
            state.matchedLocation == AppRoutes.forgotPassword ||
            state.matchedLocation == AppRoutes.splash;

        // If not authenticated and trying to access protected route
        if (!isAuthenticated && !isAuthRoute) {
          return AppRoutes.login;
        }

        // If authenticated and trying to access auth routes (except splash)
        if (isAuthenticated && 
            (state.matchedLocation == AppRoutes.login || 
             state.matchedLocation == AppRoutes.register)) {
          return AppRoutes.home;
        }

        return null;
      },
      
      routes: [
        // Splash Screen
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        
        // Auth Routes
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          name: 'forgotPassword',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        
        // Main App Routes
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        
        // Projects
        GoRoute(
          path: AppRoutes.projects,
          name: 'projects',
          builder: (context, state) => const ProjectListScreen(),
        ),
        GoRoute(
          path: AppRoutes.projectDetail,
          name: 'projectDetail',
          builder: (context, state) {
            final projectId = state.pathParameters['id'] ?? '';
            return ProjectDetailScreen(projectId: projectId);
          },
        ),
        
        // HR
        GoRoute(
          path: AppRoutes.hr,
          name: 'hr',
          builder: (context, state) => const HRScreen(),
        ),
        
        // Chat
        GoRoute(
          path: AppRoutes.chat,
          name: 'chat',
          builder: (context, state) => const ChatScreen(),
        ),
        
        // Profile
        GoRoute(
          path: AppRoutes.profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
      
      // Error handling
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri}'),
        ),
      ),
    );
  }
}
