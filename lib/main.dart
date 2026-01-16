import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/proposals_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/focus_screen.dart';
import 'models/models.dart';
import 'services/hive_service.dart';
import 'services/haptic_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/sync_migration_screen.dart';
import 'services/sync_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'constants/app_constants.dart';
import 'package:go_router/go_router.dart';
import 'router/app_router.dart';
import 'widgets/animations.dart'; // Phase 2: Animation Framework
import 'repositories/repository_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase on all platforms
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // We continue even if Firebase fails, app will handle unauthenticated state
  }
  
  try {
    // HARD BLOCK: Prevent multiple Hive initializations on Flutter Web
    if (!HiveService.isInitialized) {
      await HiveService.init();
    }
    
    // Initialize repository manager
    repositoryManager.initialize();

    // Initialize Notification Service
    await NotificationService.init();
  } catch (e) {
    debugPrint('Initialization failed: $e');
    // This is more critical, but we'll try to let the app start
  }
  
  runApp(const FreelancerApp());
}

class FreelancerApp extends StatelessWidget {
  const FreelancerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Safety check: Is Hive ready?
    if (!HiveService.isInitialized || !Hive.isBoxOpen(HiveBoxes.settings)) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 24),
                Text('Waking up the command center...', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder(
      valueListenable: Hive.box(HiveBoxes.settings).listenable(),
      builder: (context, box, _) {
        final isDarkMode = box.get(SettingsKeys.isDarkMode, defaultValue: false);
        final int primaryValue = box.get(SettingsKeys.primaryColor, defaultValue: 0xFF6366F1);
        final int accentValue = box.get(SettingsKeys.accentColor, defaultValue: 0xFF10B981);
        
        final Color primaryColor = Color(primaryValue);
        final Color accentColor = Color(accentValue);

        return MaterialApp.router(
          title: 'Freelancer App',
          debugShowCheckedModeBanner: false,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              primary: primaryColor,
              secondary: accentColor,
              surface: Colors.white,
              // ignore: deprecated_member_use
              background: const Color(0xFFF8FAFC),
            ),
            fontFamily: GoogleFonts.poppins().fontFamily,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            cardTheme: const CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
              color: Colors.white,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: Colors.white,
              indicatorColor: primaryColor.withOpacity(0.1),
              labelTextStyle: WidgetStateProperty.all(
                GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: Brightness.dark,
              primary: primaryColor,
              secondary: accentColor,
              surface: const Color(0xFF0A0A0A), // Near black
              // ignore: deprecated_member_use
              background: Colors.black, // Pure black for OLED
              onSurface: Colors.white,
            ),
            fontFamily: GoogleFonts.poppins().fontFamily,
            scaffoldBackgroundColor: Colors.black,
            cardTheme: const CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
              color: Color(0xFF0A0A0A),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: Colors.black,
              indicatorColor: primaryColor.withOpacity(0.1),
              labelTextStyle: WidgetStateProperty.all(
                GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
          
          // Use Router config
          routerConfig: AppRouter.router,
        );
      },
    );
  }

  /// Initialize cloud sync service after migration is complete
  Future<void> _initializeSync() async {
    final sync = SyncService();
    if (!sync.needsMigration && !CloudSyncService.isInitialized) {
      await CloudSyncService.init();
    }
  }

  /// Screen shown to phone auth users who need to add an email
  Widget _buildEmailRequiredScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Email Required', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.email_outlined,
              size: 80,
              color: Colors.blue[300],
            ),
            const SizedBox(height: 32),
            Text(
              'Email Required',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You signed in with a phone number. Please add an email address for account recovery and sync.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Text(
              'Please sign out and use email/Google sign-in instead.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final auth = AuthService();
                await auth.signOut();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainContainer extends StatefulWidget {
  final Widget child;
  const MainContainer({super.key, required this.child});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  Timer? _fabTimer;

  @override
  void initState() {
    super.initState();
    _fabTimer = Timer.periodic(AppDefaults.timerInterval, (timer) {
      if (mounted) {
        final box = Hive.box<TaskItem>(HiveBoxes.tasks);
        if (box.values.any((t) => t.isRunning)) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _fabTimer?.cancel();
    super.dispose();
  }

  // Calculate index based on route
  int _calculateSelectedIndex(BuildContext context) {
    // We can't access GoRouterState directly here easily without using the builder from ShellRoute.
    // However, ShellRoute passes 'child'. 
    // To get the index, we can rely on string matching the location.
    // Or better, we define the logic in 'onDestinationSelected'.
    
    // A robust way to checking location string:
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/proposals')) return 1;
    if (location.startsWith('/projects')) return 2;
    if (location.startsWith('/tasks')) return 3;
    if (location.startsWith('/invoices')) return 4;
    if (location.startsWith('/clients')) return 5;
    return 0; // dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticService.light();
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/proposals');
        break;
      case 2:
        context.go('/projects');
        break;
      case 3:
        context.go('/tasks');
        break;
      case 4:
        context.go('/invoices');
        break;
      case 5:
        context.go('/clients');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: widget.child, // The ShellRoute child
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Work'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Proposals'),
          NavigationDestination(icon: Icon(Icons.folder_open_outlined), selectedIcon: Icon(Icons.folder), label: 'Projects'),
          NavigationDestination(icon: Icon(Icons.check_circle_outlined), selectedIcon: Icon(Icons.check_circle), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Invoices'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Clients'),
        ],
      ),
      floatingActionButton: ValueListenableBuilder(
        valueListenable: Hive.box<TaskItem>(HiveBoxes.tasks).listenable(),
        builder: (context, Box<TaskItem> box, _) {
          final runningTasks = box.values.where((t) => t.isRunning);
          if (runningTasks.isEmpty) return const SizedBox.shrink();

          final activeTask = runningTasks.first;
          final duration = Duration(seconds: activeTask.totalSeconds + DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(activeTask.lastStartTime!)).inSeconds);
          final formatted = '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

          return Container(
            margin: const EdgeInsets.only(bottom: 60), // Above BottomBar
            child: FloatingActionButton.extended(
              onPressed: () {
                 // Requires modifying FocusScreen to be a route or keeping push
                 // Pushing on top of Shell is fine for modals/focus
                 Navigator.push(context, MaterialPageRoute(builder: (_) => FocusScreen(task: activeTask)));
              },
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.timer, color: Colors.greenAccent),
              label: Text('$formatted • ${activeTask.title}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
