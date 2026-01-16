import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../repositories/repository_manager.dart';
import '../widgets/project_story_timeline.dart';
import '../widgets/app_card.dart';
import '../services/haptic_service.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Project Story', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: StreamBuilder<List<Proposal>>(
        stream: repositoryManager.proposals.getAll(),
        initialData: repositoryManager.proposals.getAllSync(),
        builder: (context, proposalSnapshot) {
          return StreamBuilder<List<Invoice>>(
            stream: repositoryManager.invoices.getAll(),
            initialData: repositoryManager.invoices.getAllSync(),
            builder: (context, invoiceSnapshot) {
              return StreamBuilder<List<TaskItem>>(
                stream: repositoryManager.tasks.getAll(),
                initialData: repositoryManager.tasks.getAllSync(),
                builder: (context, taskSnapshot) {
                  if (!proposalSnapshot.hasData || !invoiceSnapshot.hasData || !taskSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final timelineNodes = _buildStoryNodes(
                    project,
                    proposalSnapshot.data!,
                    invoiceSnapshot.data!,
                    taskSnapshot.data!,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 32),
                        Text(
                          'THE JOURNEY',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ProjectStoryTimeline(nodes: timelineNodes),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  project.status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '\$${project.budget.toInt()}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            project.name,
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Client: ${project.clientName}',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  List<TimelineNode> _buildStoryNodes(
    Project project,
    List<Proposal> allProposals,
    List<Invoice> allInvoices,
    List<TaskItem> allTasks,
  ) {
    final List<TimelineNode> nodes = [];

    // 1. Find matching proposal
    final proposal = allProposals.firstWhere(
      (p) => p.projectTitle.toLowerCase() == project.name.toLowerCase() || 
             (p.clientName == project.clientName && p.status == 'Accepted'),
      orElse: () => Proposal(
        id: '', clientName: '', projectTitle: '', description: '', 
        estimatedBudget: 0, dateSent: project.deadline.subtract(const Duration(days: 30))
      ),
    );

    if (proposal.id.isNotEmpty) {
      nodes.add(TimelineNode(
        title: 'Proposal Accepted',
        subtitle: 'The vision was shared and agreed upon.',
        date: proposal.dateSent,
        icon: Icons.description_outlined,
        color: Colors.blue,
      ));
    }

    // 2. Project Commenced
    nodes.add(TimelineNode(
      title: 'Project Kickoff',
      subtitle: 'Work officially started on this project.',
      date: project.deadline.subtract(const Duration(days: 21)), // Hypothetical start date
      icon: Icons.rocket_launch_outlined,
      color: Colors.purple,
    ));

    // 3. Significant Task Completion (Last task completed?)
    final projectTasks = allTasks.where((t) => t.projectId == project.id && t.isCompleted).toList();
    if (projectTasks.isNotEmpty) {
      nodes.add(TimelineNode(
        title: '${projectTasks.length} Milestones Reached',
        subtitle: 'Consistent progress being made.',
        date: DateTime.now(), // Simplified
        icon: Icons.check_circle_outline,
        color: Colors.green,
      ));
    }

    // 4. Invoices
    final projectInvoices = allInvoices.where((i) => i.projectId == project.id).toList();
    for (var inv in projectInvoices) {
      nodes.add(TimelineNode(
        title: inv.status == 'Paid' ? 'Payment Received' : 'Invoice Sent',
        subtitle: inv.status == 'Paid' ? 'Fuel for the journey secured.' : 'Awaiting business results.',
        date: inv.date,
        icon: inv.status == 'Paid' ? Icons.payments_outlined : Icons.receipt_long_outlined,
        color: inv.status == 'Paid' ? Colors.green : Colors.orange,
      ));
    }

    // Sort nodes by date
    nodes.sort((a, b) => a.date.compareTo(b.date));
    return nodes;
  }
}
