import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart'; // import for MainContainer
import '../models/models.dart';
import '../screens/login_screen.dart';
import '../screens/email_verification_screen.dart';
import '../screens/sync_migration_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/proposals_screen.dart';
import '../screens/projects_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/invoices_screen.dart';
import '../screens/clients_screen.dart';
import '../screens/project_details_screen.dart';
import '../screens/trust_center_screen.dart';
import '../screens/weekly_review_screen.dart';
import '../services/sync_service.dart';
import '../constants/app_constants.dart';
import '../repositories/repository_manager.dart';

// Global key for navigation
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static GoRouter? _router;

  static GoRouter get router {
    if (_router != null) return _router!;

    // Safely get auth changes stream
    Stream<User?> authStream;
    try {
      authStream = FirebaseAuth.instance.authStateChanges();
    } catch (e) {
      debugPrint('Firebase not available for router: $e');
      authStream = Stream<User?>.empty();
    }

    _router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authStream),
      redirect: (context, state) {
        // Safe access to auth and repositories
        User? user;
        try {
          user = FirebaseAuth.instance.currentUser;
        } catch (e) {
          user = null;
        }
        
        final bool isLoggedIn = user != null;
        final bool isLoggingIn = state.uri.toString() == '/login';
        final bool isVerifying = state.uri.toString() == '/verify-email';
        final bool isSyncing = state.uri.toString() == '/sync';

        // 1. Not logged in -> Login
        if (!isLoggedIn) {
          return isLoggingIn ? null : '/login';
        }

        // 2. Logged in check
        if (isLoggedIn) {
          // Migration Check - handle repository potential unreadiness
          bool isMigrated = false;
          try {
             isMigrated = repositoryManager.settings.get(SettingsKeys.isCloudMigrated, defaultValue: false);
          } catch (e) {
             debugPrint('Settings not ready for redirect: $e');
             // If repositories aren't ready, don't redirect yet to avoid loops
             return null;
          }

          if (!isMigrated) {
               if (isSyncing) return null;
               return '/sync';
          }

          if (isLoggingIn || isVerifying || isSyncing) {
             return '/';
          }
        }

        return null;
      },
      routes: [
      // Splash - handled by initial routes usually, but we can make it explicit if needed.
      // For now we rely on redirect logic to determine where to go.
      
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/sync',
        name: 'sync-migration',
        builder: (context, state) => SyncMigrationScreen(
          onComplete: () {
             // Reload settings or force refresh
             // Navigate to home
             context.go('/');
          },
        ),
      ),
      
      // Shell Route for Bottom Navigation
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return MainContainer(child: child); 
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/proposals',
            name: 'proposals',
            builder: (context, state) => const ProposalsScreen(),
          ),
          GoRoute(
            path: '/projects',
            name: 'projects',
            builder: (context, state) => const ProjectsScreen(),
          ),
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/invoices',
            name: 'invoices',
            builder: (context, state) => const InvoicesScreen(),
          ),
          GoRoute(
            path: '/clients',
            name: 'clients',
            builder: (context, state) => const ClientsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/project-detail',
        name: 'project-detail',
        builder: (context, state) {
          final project = state.extra as Project;
          return ProjectDetailScreen(project: project);
        },
      ),
      GoRoute(
        path: '/trust-center',
        name: 'trust-center',
        builder: (context, state) => const TrustCenterScreen(),
      ),
      GoRoute(
        path: '/weekly-review',
        name: 'weekly-review',
        builder: (context, state) => const WeeklyReviewScreen(),
      ),
    ],
    );
    
    return _router!;
  }
}

// Helper class for auth stream listening
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
