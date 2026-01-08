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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Hive init is now handled in SplashScreen
  runApp(const FreelancerApp());
}

class FreelancerApp extends StatelessWidget {
  const FreelancerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: Theme listener starts weak here, but updates once Settings box opens in Splash
    // We wrap in a builder that handles the async nature safely or defaults to light
    return MaterialApp(
      title: 'Freelancer App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: GoogleFonts.poppins().fontFamily,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        cardColor: Colors.white,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: GoogleFonts.poppins().fontFamily,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
             TargetPlatform.android: ZoomPageTransitionsBuilder(),
             TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
             TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: ThemeMode.system, // Will be overridden by ValueListenable in MainContainer if needed, 
                                   // or we can update this widget to listen to Hive *after* Init.
                                   // For Splash, we default to System or Light.
      home: const SplashScreen(),
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

  final List<Widget> _screens = [
    DashboardScreen(),
    ProposalsScreen(),
    ProjectsScreen(),
    TasksScreen(),
    InvoicesScreen(),
    ClientsScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
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
