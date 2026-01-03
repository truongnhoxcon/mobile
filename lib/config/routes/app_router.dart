import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../dependencies/injection_container.dart';
import '../../presentation/widgets/layout/main_layout.dart';

import '../../domain/entities/chat_room.dart';
import '../../presentation/blocs/blocs.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/home/hr_home_screen.dart';
import '../../presentation/screens/home/pm_home_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/projects/project_list_screen.dart';
import '../../presentation/screens/projects/project_detail_screen.dart';
import '../../presentation/screens/hr/hr_screen.dart';
import '../../presentation/screens/chat/chat_list_screen.dart';
import '../../presentation/screens/chat/chat_room_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/ai_chat/ai_chat_screen.dart';
import '../../presentation/screens/pm/create_project_screen.dart';
import '../../presentation/screens/pm/create_task_screen.dart';
import '../../presentation/screens/pm/task_detail_screen.dart';
import '../../presentation/screens/employee/employee_tasks_screen.dart';
import '../../presentation/screens/employee/my_info_screen.dart';
import '../../presentation/screens/leave/leave_request_screen.dart';
import '../../presentation/screens/attendance/attendance_screen.dart';
import '../../presentation/screens/salary/salary_screen.dart';
import '../../presentation/screens/notification/notification_screen.dart';
import '../../presentation/screens/files/files_screen.dart';
import '../../presentation/screens/employee/my_evaluations_screen.dart';
import '../../presentation/screens/profile/change_password_screen.dart';
import '../../presentation/screens/profile/team_screen.dart';
import '../../presentation/screens/hr/department_detail_screen.dart';
import '../../presentation/screens/home/admin_home_screen.dart';
import '../../presentation/screens/admin/account_management_screen.dart';

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
  static const String aiChat = '/ai-chat';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String pmCreateProject = '/pm/create-project';
  static const String pmCreateTask = '/pm/create-task';
  static const String taskDetail = '/employee/tasks/task/:id'; // Updated nesting
  static const String employeeTasks = '/employee/tasks';
  static const String myInfo = '/profile/my-info'; // Updated nesting
  static const String myEvaluations = '/profile/my-evaluations'; // Updated nesting
  static const String files = '/files';
  static const String changePassword = '/profile/change-password'; // Updated nesting
  static const String team = '/profile/team'; // Updated nesting
  static const String departmentDetail = '/hr/department/:id';
  static const String admin = '/admin';
  static const String adminAccounts = '/admin/accounts';
}

/// App Router
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    
    // Redirect based on auth state
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoading = authState.status == AuthStatus.loading;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword ||
          state.matchedLocation == AppRoutes.splash;

      // If still loading, don't redirect
      if (isLoading) {
        print('[Router] Auth loading, no redirect');
        return null;
      }

      print('[Router] Path: ${state.matchedLocation}, Auth: $isAuthenticated');

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
      
      // Main Application Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) {
                  return BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                       if (authState.user == null && authState.status == AuthStatus.authenticated) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          context.read<AuthBloc>().add(AuthCheckRequested());
                        });
                        return const Scaffold(body: Center(child: CircularProgressIndicator()));
                      }
                      final isAdmin = authState.user?.isAdmin ?? false;
                      final isHRManager = authState.user?.isHRManager ?? false;
                      final isProjectManager = authState.user?.isProjectManager ?? false;
                      
                      if (isAdmin) {
                        return const AdminHomeScreen();
                      }
                      if (isHRManager) {
                        return const HRHomeScreen();
                      }
                      if (isProjectManager) {
                        return const PMHomeScreen();
                      }

                      return BlocProvider(
                        create: (_) {
                          final userId = authState.user?.id ?? '';
                          return sl<AttendanceBloc>()..add(AttendanceLoadToday(userId));
                        },
                        child: const HomeScreen(),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          
          // Branch 2: Work (Tasks)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.employeeTasks,
                name: 'employeeTasks',
                builder: (context, state) => const EmployeeTasksScreen(),
                routes: [
                  GoRoute(
                    path: 'task/:id',
                    name: 'taskDetail',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => TaskDetailScreen(taskId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          
          // Branch 3: Chat
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                name: 'chat',
                builder: (context, state) => const ChatListScreen(),
                routes: [
                  GoRoute(
                    path: ':roomId',
                    name: 'chatRoom',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final room = state.extra as ChatRoom?;
                      return ChatRoomScreen(
                        roomId: state.pathParameters['roomId']!,
                        room: room,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          
          // Branch 4: HR
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.hr,
                name: 'hr',
                builder: (context, state) => const HRScreen(),
                routes: [
                  GoRoute(
                     path: 'salary',
                     name: 'salary',
                     parentNavigatorKey: _rootNavigatorKey,
                     builder: (context, state) => const SalaryScreen(),
                  ),
                  GoRoute(
                     path: 'leave',
                     name: 'leave',
                     parentNavigatorKey: _rootNavigatorKey,
                     builder: (context, state) => const LeaveRequestScreen(),
                  ),
                   GoRoute(
                     path: 'attendance',
                     name: 'attendance',
                     parentNavigatorKey: _rootNavigatorKey,
                     builder: (context, state) => const AttendanceScreen(),
                  ),
                ],
              ),
            ],
          ),
          
          // Branch 5: Personal
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'my-info', 
                    name: 'myInfo',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const MyInfoScreen(),
                  ),
                  GoRoute(
                    path: 'change-password', 
                    name: 'changePassword',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ChangePasswordScreen(),
                  ),
                  GoRoute(
                    path: 'team', 
                    name: 'team',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const TeamScreen(),
                  ),
                   GoRoute(
                    path: 'my-evaluations', 
                    name: 'myEvaluations',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const MyEvaluationsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      
      // Standalone Roots (Overlay Shell)
      GoRoute(
        path: AppRoutes.projects,
        name: 'projects',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProjectListScreen(),
        routes: [
           GoRoute(
            path: ':id', // /projects/:id
            name: 'projectDetail',
            builder: (context, state) => ProjectDetailScreen(projectId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.files,
        name: 'files',
        parentNavigatorKey: _rootNavigatorKey, // Files from home quick access (if any) or standalone
        builder: (context, state) => const FilesScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiChat,
        name: 'aiChat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AIChatScreen(),
      ),
       GoRoute(
        path: AppRoutes.pmCreateProject,
        name: 'pmCreateProject',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateProjectScreen(),
      ),
       GoRoute(
        path: AppRoutes.pmCreateTask,
        name: 'pmCreateTask',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateTaskScreen(),
      ),
      GoRoute(
        path: AppRoutes.departmentDetail,
        name: 'departmentDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final departmentId = state.pathParameters['id'] ?? '';
          return BlocProvider.value(
            value: sl<HRBloc>(),
            child: DepartmentDetailScreen(departmentId: departmentId),
          );
        },
      ),
      // Admin Routes
      GoRoute(
        path: AppRoutes.admin,
        name: 'admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAccounts,
        name: 'adminAccounts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountManagementScreen(),
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
