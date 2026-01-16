import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../app_card.dart';

class SmartInsightCard extends StatelessWidget {
  final List<Invoice> invoices;
  final List<Project> activeProjects;
  final List<Proposal> proposals;

  const SmartInsightCard({
    super.key,
    required this.invoices,
    required this.activeProjects,
    required this.proposals,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Identify critical issues
    final overdue = invoices.where((i) => i.status == 'Pending' && i.date.isBefore(DateTime.now())).toList();
    final nearDeadline = activeProjects.where((p) => p.deadline.difference(DateTime.now()).inDays <= 3 && p.deadline.isAfter(DateTime.now())).toList();
    final pendingProposals = proposals.where((p) => p.status == 'Pending').toList();

    String title = "Smart Insight";
    String message = "All systems go! You're dominating your workflow today.";
    IconData icon = Icons.check_circle_outline;
    Color color = Colors.green;

    if (overdue.isNotEmpty) {
       title = "Action Required";
       message = "You have ${overdue.length} overdue invoice(s). Time to nudge ${overdue.first.clientName}?";
       icon = Icons.priority_high;
       color = Colors.orange;
    } else if (nearDeadline.isNotEmpty) {
       title = "Upcoming Deadline";
       message = "${nearDeadline.first.name} is due very soon. Let's wrap it up!";
       icon = Icons.alarm;
       color = Colors.blue;
    } else if (pendingProposals.isNotEmpty) {
       title = "Opportunity";
       message = "Don't forget to follow up on your proposal for ${pendingProposals.first.clientName}.";
       icon = Icons.auto_awesome;
       color = const Color(0xFF6366F1);
    }

    return AppCard(
      color: color.withOpacity(0.05),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}
