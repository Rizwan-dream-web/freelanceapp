import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../widgets/quick_notes_sheet.dart';
import '../widgets/global_search_delegate.dart';
import '../services/currency_service.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';
import '../widgets/app_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final taskBox = Hive.box<TaskItem>('tasks');
        if (taskBox.values.any((t) => t.isRunning)) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Command Center', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(context: context, delegate: GlobalSearchDelegate()),
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline), // Idea Box
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const QuickNotesSheet(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Project>('projects').listenable(),
        builder: (context, Box<Project> projectBox, _) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<Invoice>('invoices').listenable(),
            builder: (context, Box<Invoice> invoiceBox, _) {
              return ValueListenableBuilder(
                 valueListenable: Hive.box<TaskItem>('tasks').listenable(),
                 builder: (context, Box<TaskItem> taskBox, _) {
                    
                    // --- Data Processing ---
                    final projects = projectBox.values.toList();
                    final invoices = invoiceBox.values.toList();
                    final tasks = taskBox.values.toList();

                    // 1. Daily Focus (Most urgent active project)
                    final activeProjects = projects.where((p) => p.status == 'In Progress' && p.deadline.isAfter(DateTime.now())).toList();
                    activeProjects.sort((a, b) => a.deadline.compareTo(b.deadline));
                    final focusProject = activeProjects.isNotEmpty ? activeProjects.first : null;

                    // 2. Multi-currency Income (Converted to Global)
                    final paidInvoices = invoices.where((i) => i.status == 'Paid').toList();
                    double totalPaidConverted = paidInvoices.fold(0.0, (sum, i) => sum + CurrencyService.convert(i.amount, i.currency));

                    final nextWeek = DateTime.now().add(const Duration(days: 7));
                    double expectedConverted = invoices
                        .where((i) => i.status == 'Pending' && i.date.isBefore(nextWeek))
                        .fold(0.0, (sum, i) => sum + CurrencyService.convert(i.amount, i.currency));

                    // 3. Time Burn (Total estimated vs Total tracked for Active Projects)
                    int totalEstimated = 0;
                    int totalTrackedSeconds = 0;
                    final now = DateTime.now().millisecondsSinceEpoch;
                    
                    for (var p in activeProjects) {
                       totalEstimated += p.estimatedHours;
                       final projectTasks = tasks.where((t) => t.projectId == p.id).toList();
                       for (var t in projectTasks) {
                         totalTrackedSeconds += t.totalSeconds;
                         if (t.isRunning && t.lastStartTime != null) {
                           totalTrackedSeconds += ((now - t.lastStartTime!) / 1000).floor();
                         }
                       }
                    }
                    final totalTrackedHours = totalTrackedSeconds / 3600;
                    final burnRate = totalEstimated == 0 ? 0.0 : (totalTrackedHours / totalEstimated).clamp(0.0, 1.0);

                    // 4. Action Alerts
                    final overdueInvoices = invoices.where((i) => i.status == 'Pending' && i.date.isBefore(DateTime.now())).length;
                    final pendingProposals = Hive.box<Proposal>('proposals').values.where((p) => p.status == 'Pending').length;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Welcome Message ---
                          Text('Good evening, Rizwan', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('Ready to crush your goals today?', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 25),

                          // --- Daily Focus Card ---
                          if (focusProject != null) ...[
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Text('DAILY FOCUS', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                                 const Icon(Icons.star, color: Colors.amber, size: 16),
                               ],
                             ),
                             const SizedBox(height: 10),
                             _buildFocusCard(context, focusProject, tasks),
                             const SizedBox(height: 25),
                          ],

                          // --- Storytelling Insight (SMART) ---
                          if (paidInvoices.isNotEmpty) ...[
                            AppCard(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 24),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Smart Insight', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1))),
                                        Text(
                                          totalPaidConverted > 0 
                                            ? 'You earned more this month than last! Keep the momentum high. 🚀'
                                            : 'No earnings yet this month. Time to follow up on your pending proposals!',
                                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // --- Time Burn Indicator ---
                          if (activeProjects.isNotEmpty) ...[
                             _buildTimeBurnCard(context, totalTrackedHours, totalEstimated, burnRate),
                             const SizedBox(height: 25),
                          ],

                          Text('FINANCIAL SNAPSHOT', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildStatCard(context, 'Total Paid', CurrencyService.format(totalPaidConverted, CurrencyService.globalCurrency), Icons.payments_outlined, Colors.indigo)),
                              const SizedBox(width: 15),
                              Expanded(child: _buildStatCard(context, 'Next Week', CurrencyService.format(expectedConverted, CurrencyService.globalCurrency), Icons.event_available_outlined, Colors.teal)),
                            ],
                          ),

                          const SizedBox(height: 25),
                          
                          // --- Action Alerts (Button Style) ---
                          if (overdueInvoices > 0 || pendingProposals > 0) ...[
                             Text('QUICK ACTIONS', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                             const SizedBox(height: 10),
                             if (overdueInvoices > 0)
                               _buildActionChip(context, 'Invoice Follow-up ($overdueInvoices)', Icons.mail_outline, Colors.orange),
                             if (pendingProposals > 0)
                               _buildActionChip(context, 'New Proposal Response', Icons.description_outlined, Colors.blue),
                          ],
                        ],
                      ),

                    );
                 }
              );
            }
          );
        }
      ),
    );
  }

  Widget _buildFocusCard(BuildContext context, Project project, List<TaskItem> allTasks) {
    // Determine progress for this specific project
    final pTasks = allTasks.where((t) => t.projectId == project.id).toList();
    final completed = pTasks.where((t) => t.isCompleted).length;
    final progress = pTasks.isEmpty ? 0.0 : completed / pTasks.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF1976D2)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text('PRIORITY', style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Icon(Icons.star, color: Colors.white.withOpacity(0.8)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(project.name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(
                CurrencyService.format(project.budget, project.currency),
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(project.clientName, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 16)),
          const SizedBox(height: 20),
          
          // Mini Task Preview
          if (pTasks.isNotEmpty) 
             ...pTasks.take(2).map((t) => Padding(
               padding: const EdgeInsets.only(bottom: 6),
               child: Row(
                 children: [
                   Icon(t.isCompleted ? Icons.check_circle : Icons.circle_outlined, color: Colors.white70, size: 16),
                   const SizedBox(width: 8),
                   Text(t.title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, decoration: t.isCompleted ? TextDecoration.lineThrough : null)),
                 ],
               ),
             )),

          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.black12,
            color: Colors.white,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 6),
          Text('Deadline: ${DateFormat.MMMd().format(project.deadline)}', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTimeBurnCard(BuildContext context, double tracked, int estimated, double burnRate) {
    Color burnColor = burnRate > 1.0 ? Colors.red : (burnRate > 0.8 ? Colors.orange : Theme.of(context).colorScheme.primary);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60, height: 60,
                child: CircularProgressIndicator(
                  value: burnRate > 1 ? 1 : burnRate,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  color: burnColor,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Icon(Icons.timer_outlined, color: burnColor, size: 24),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TIME PROGRESS', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(
                  '${tracked.toStringAsFixed(1)} / $estimated hrs', 
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: burnRate > 1 ? 1 : burnRate,
                    backgroundColor: burnColor.withOpacity(0.1),
                    color: burnColor,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  burnRate > 1.0 ? 'Over Budget!' : '${((1-burnRate)*100).toInt()}% capacity left',
                  style: GoogleFonts.poppins(color: burnColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(title, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, String label, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: color.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.2))),
        leading: Icon(icon, color: color),
        title: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          // Navigation logic could be added here
        },
      ),
    );
  }
}
