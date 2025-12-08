/// App Router Configuration
/// 
/// Defines all routes and navigation logic using go_router.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/projects/projects_screen.dart';
import '../../presentation/screens/hr/hr_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';

/// App Route Names
class AppRoutes {
  AppRoutes._();
  
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
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

  static final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
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
        builder: (context, state) => const ProjectsScreen(),
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
