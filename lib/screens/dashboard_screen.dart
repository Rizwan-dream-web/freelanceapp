import 'dart:async';
import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/currency_service.dart';
import '../widgets/app_card.dart';
import '../services/haptic_service.dart';
import '../widgets/animations.dart';
import '../widgets/loading.dart';
import '../widgets/buttons.dart';
import 'invoices_screen.dart';
import 'proposals_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/command_search.dart';
import '../widgets/quick_notes_sheet.dart';
import 'settings_screen.dart';
import '../repositories/repository_manager.dart';

// Refactored Widgets
import '../widgets/dashboard/focus_card.dart';
import '../widgets/dashboard/time_burn_card.dart';
import '../widgets/dashboard/smart_insight_card.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/dashboard/daily_effort_banner.dart';
import '../widgets/dashboard/dashboard_action_chip.dart';
import '../widgets/staggered_anim.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  String? _userName;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _animController.forward();
    });

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (mounted) {
        final tasks = await repositoryManager.tasks.getAllOnce();
        if (tasks.any((t) => t.isRunning)) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String name = user.displayName ?? '';
    if (name.isEmpty && (user.email ?? '').isNotEmpty) {
      final email = user.email!;
      name = email.split('@').first;
      name = name.isNotEmpty ? '${name[0].toUpperCase()}${name.substring(1)}' : 'You';
    }

    if (mounted) {
      setState(() => _userName = name.isEmpty ? 'You' : name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Command Center', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Theme.of(context).colorScheme.surface.withOpacity(0.5)),
          ),
        ),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          AnimatedIconButton(
            icon: Icons.search,
            tooltip: 'Search',
            onPressed: () {
              HapticService.light();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const CommandSearch(),
              );
            },
          ),
          AnimatedIconButton(
            icon: Icons.lightbulb_outline,
            tooltip: 'Quick Notes',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => QuickNotesSheet(),
            ),
          ),
          AnimatedIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen())),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Elegant Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E1E2C).withOpacity(0.05),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          
          StreamBuilder<List<Project>>(
            stream: repositoryManager.projects.getAll(),
            initialData: repositoryManager.projects.getAllSync(),
            builder: (context, projectSnapshot) {
              return StreamBuilder<List<Invoice>>(
                stream: repositoryManager.invoices.getAll(),
                initialData: repositoryManager.invoices.getAllSync(),
                builder: (context, invoiceSnapshot) {
                  return StreamBuilder<List<TaskItem>>(
                    stream: repositoryManager.tasks.getAll(),
                    initialData: repositoryManager.tasks.getAllSync(),
                    builder: (context, taskSnapshot) {
                      return StreamBuilder<List<Proposal>>(
                        stream: repositoryManager.proposals.getAll(),
                        initialData: repositoryManager.proposals.getAllSync(),
                        builder: (context, proposalSnapshot) {
                          if (!projectSnapshot.hasData || !invoiceSnapshot.hasData || !taskSnapshot.hasData || !proposalSnapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final projects = projectSnapshot.data!;
                          final invoices = invoiceSnapshot.data!;
                          final tasks = taskSnapshot.data!;
                          final proposals = proposalSnapshot.data!;

                          // --- Data Calculations ---
                          
                          // 1. Weekly Effort
                          List<double> weeklyData = [];
                          List<String> dayLabels = [];
                          double todayTrackedSeconds = 0;
                          final now = DateTime.now();
                          
                          for (int i = 6; i >= 0; i--) {
                            final date = now.subtract(Duration(days: i));
                            final dateKey = DateFormat('yyyy-MM-dd').format(date);
                            dayLabels.add(DateFormat('E').format(date));
                            
                            double daySeconds = 0;
                            for (var t in tasks) {
                              daySeconds += (t.dailyTracked[dateKey] ?? 0);
                              if (i == 0 && t.isRunning && t.lastStartTime != null) {
                                  daySeconds += ((DateTime.now().millisecondsSinceEpoch - t.lastStartTime!) / 1000).floor();
                              }
                            }
                            weeklyData.add(daySeconds / 3600);
                            if (i == 0) todayTrackedSeconds = daySeconds;
                          }
                          final todayTrackedHours = todayTrackedSeconds / 3600;

                          // 2. Daily Focus (Best match project)
                          final activeProjects = projects.where((p) => p.status == 'In Progress').toList();
                          activeProjects.sort((a, b) {
                            final chaseComparison = b.chaseStatus.index.compareTo(a.chaseStatus.index);
                            if (chaseComparison != 0) return chaseComparison;
                            return a.deadline.compareTo(b.deadline);
                          });
                          final focusProject = activeProjects.isNotEmpty ? activeProjects.first : null;

                          // 3. Smart Insight
                          final overdueCount = invoices.where((i) => i.status == 'Pending' && i.date.isBefore(DateTime.now())).length;
                          final pendingAmtConverted = invoices
                              .where((i) => i.status == 'Pending')
                              .fold(0.0, (sum, i) => sum + CurrencyService.convert(i.amount, i.currency));
                          
                          String? smartInsight;
                          if (focusProject != null && focusProject.chaseStatus != ProjectChaseStatus.onTrack) {
                            smartInsight = "${focusProject.name} is ${focusProject.chaseStatusLabel.toLowerCase()}. Check deadline!";
                          } else if (overdueCount > 0) {
                            smartInsight = "$overdueCount invoices overdue, ${CurrencyService.format(pendingAmtConverted, 'INR')} pending";
                          } else if (pendingAmtConverted > 0) {
                            smartInsight = "${CurrencyService.format(pendingAmtConverted, 'INR')} in pending payments";
                          }

                          // 4. Time Burn
                          int totalEstimatedHours = focusProject?.estimatedHours ?? 0;
                          double projectTrackedHours = 0;
                          if (focusProject != null) {
                            final projectTasks = tasks.where((t) => t.projectId == focusProject.id).toList();
                            int projectTrackedSeconds = projectTasks.fold(0, (sum, t) => sum + t.totalSeconds);
                            for (var t in projectTasks) {
                              if (t.isRunning && t.lastStartTime != null) {
                                projectTrackedSeconds += ((DateTime.now().millisecondsSinceEpoch - t.lastStartTime!) / 1000).floor();
                              }
                            }
                            projectTrackedHours = projectTrackedSeconds / 3600;
                          }
                          final showTimeBurn = totalEstimatedHours > 0;

                          // 5. Finance
                          final thisMonth = DateTime.now().month;
                          final totalPaidConverted = invoices
                              .where((i) => i.status == 'Paid' && i.date.month == thisMonth)
                              .fold(0.0, (sum, i) => sum + CurrencyService.convert(i.amount, i.currency));
                          
                          final next7Days = DateTime.now().add(const Duration(days: 7));
                          final pending7DaysConverted = invoices
                              .where((i) => i.status == 'Pending' && i.date.isBefore(next7Days))
                              .fold(0.0, (sum, i) => sum + CurrencyService.convert(i.amount, i.currency));

                          // 6. Quick Actions
                          List<Widget> contextualActions = [];
                          if (overdueCount > 0) {
                            contextualActions.add(DashboardActionChip(
                                label: 'Follow-up on overdue payments',
                                icon: Icons.mail_outline,
                                color: Colors.orange,
                                onPressed: () => context.push('/invoices'),
                            ));
                          }
                          if (focusProject != null && focusProject.chaseStatus == ProjectChaseStatus.needsAttention) {
                            contextualActions.add(DashboardActionChip(
                                label: 'Review ${focusProject.name} deadline',
                                icon: Icons.error_outline,
                                color: Colors.redAccent,
                                onPressed: () => context.push('/projects'),
                            ));
                          }
                          final pendingProposals = proposals.where((p) => p.status == 'Pending').length;
                          if (pendingProposals > 0) {
                              contextualActions.add(DashboardActionChip(
                                label: 'Respond to $pendingProposals proposals',
                                icon: Icons.description_outlined,
                                color: Colors.blueAccent,
                                onPressed: () => context.push('/proposals'),
                              ));
                          }

                          return SingleChildScrollView(
                            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 70, left: 20, right: 20, bottom: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hello, ${_userName ?? 'Champion'} —', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 24),
                                
                                // 1. Daily Effort Chart
                                StaggeredAnim(
                                  index: 0,
                                  controller: _animController,
                                  child: DailyEffortBanner(
                                    weeklyData: weeklyData,
                                    dayLabels: dayLabels,
                                    todayHours: todayTrackedHours,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // 2. Daily Focus (Single Project)
                                if (focusProject != null) ...[
                                  _sectionTitle('DAILY FOCUS'),
                                  StaggeredAnim(
                                    index: 1,
                                    controller: _animController,
                                    child: FocusCard(project: focusProject, allTasks: tasks),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // 3. Smart Insight
                                if (smartInsight != null) ...[
                                  StaggeredAnim(
                                    index: 2,
                                    controller: _animController,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.auto_awesome, size: 18, color: Theme.of(context).colorScheme.primary),
                                          const SizedBox(width: 12),
                                          Expanded(child: Text(smartInsight, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold))),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // 4. Time Burn Card
                                if (showTimeBurn && focusProject != null) ...[
                                  _sectionTitle('TIME BURN'),
                                  StaggeredAnim(
                                    index: 3,
                                    controller: _animController,
                                    child: TimeBurnCard(
                                      tracked: projectTrackedHours,
                                      estimated: totalEstimatedHours.toDouble(),
                                      burnRate: projectTrackedHours / totalEstimatedHours,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // 5. Financial Snapshot
                                _sectionTitle('FINANCIAL SNAPSHOT'),
                                StaggeredAnim(
                                  index: 4,
                                  controller: _animController,
                                  child: Row(
                                    children: [
                                      Expanded(child: StatCard(title: 'Total Paid (Mo)', value: totalPaidConverted, icon: Icons.payments, color: Colors.green, isCurrency: true)),
                                      const SizedBox(width: 12),
                                      Expanded(child: StatCard(title: 'Pending (7d)', value: pending7DaysConverted, icon: Icons.pending_actions, color: Colors.indigo, isCurrency: true)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // 6. Quick Actions
                                if (contextualActions.isNotEmpty) ...[
                                  _sectionTitle('QUICK ACTIONS'),
                                  StaggeredAnim(
                                    index: 5,
                                    controller: _animController,
                                    child: Column(children: contextualActions),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 2),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
    );
  }
}
