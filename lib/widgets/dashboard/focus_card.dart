import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../screens/focus_screen.dart';
import '../animations.dart';
import '../buttons.dart';

class FocusCard extends StatelessWidget {
  final Project project;
  final List<TaskItem> allTasks;

  const FocusCard({
    super.key,
    required this.project,
    required this.allTasks,
  });

  @override
  Widget build(BuildContext context) {
    // Determine progress for this specific project
    final pTasks = allTasks.where((t) => t.projectId == project.id).toList();
    final completed = pTasks.where((t) => t.isCompleted).length;
    final progress = pTasks.isEmpty ? 0.0 : (completed / pTasks.length).clamp(0.0, 1.0);

    Color statusColor;
    switch (project.chaseStatus) {
      case ProjectChaseStatus.onTrack: statusColor = Colors.greenAccent; break;
      case ProjectChaseStatus.atRisk: statusColor = Colors.orangeAccent; break;
      case ProjectChaseStatus.needsAttention: statusColor = Colors.redAccent; break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1),
            const Color(0xFF4338CA).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
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
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  project.chaseStatusLabel.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Icon(Icons.rocket_launch, color: Colors.white70, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            project.name,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Deadline: ${DateFormat('dd MMM yyyy').format(project.deadline)}',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PROGRESS', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                        Text('${(progress * 100).toInt()}%', style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      color: Colors.white,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              AnimatedButton(
                onPressed: () {
                   final pTasks = allTasks.where((t) => t.projectId == project.id).toList();
                   final taskToStart = pTasks.where((t) => !t.isCompleted).firstOrNull;
                   if (taskToStart != null) {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => FocusScreen(task: taskToStart)));
                   } else {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All tasks done! Add more?')));
                   }
                },
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                borderRadius: BorderRadius.circular(10),
                child: Text('WORK', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
