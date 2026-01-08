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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const FreelancerApp());
}

class FreelancerApp extends StatelessWidget {
  const FreelancerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, box, _) {
        final isDarkMode = box.get('isDarkMode', defaultValue: false);
        final int primaryValue = box.get('primaryColor', defaultValue: 0xFF6366F1);
        final int accentValue = box.get('accentColor', defaultValue: 0xFF10B981);
        
        final Color primaryColor = Color(primaryValue);
        final Color accentColor = Color(accentValue);

        return MaterialApp(
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
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: ZoomPageTransitionsBuilder(),
              },
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
              background: Colors.black, // Pure black for OLED
              onBackground: Colors.white,
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
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                 TargetPlatform.android: ZoomPageTransitionsBuilder(),
                 TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                 TargetPlatform.windows: ZoomPageTransitionsBuilder(),
              },
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;

  Timer? _fabTimer;

  @override
  void initState() {
    super.initState();
    _fabTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final box = Hive.box<TaskItem>('tasks');
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

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProposalsScreen(),
    const ProjectsScreen(),
    const TasksScreen(),
    const InvoicesScreen(),
    const ClientsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          HapticService.light();
          setState(() => _currentIndex = index);
        },
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
        valueListenable: Hive.box<TaskItem>('tasks').listenable(),
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
