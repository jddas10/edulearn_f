import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/student/student_dashboard_screen.dart';
import '../screens/teacher/teacher_dashboard_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const role = '/role';
  static const login = '/login';
  static const studentDash = '/student';
  static const teacherDash = '/teacher';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.role,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'student';
          return LoginScreen(role: role);
        },
      ),
      GoRoute(
        path: AppRoutes.studentDash,
        builder: (context, state) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherDash,
        builder: (context, state) => const TeacherDashboardScreen(),
      ),
    ],
  );
}
