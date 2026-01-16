import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'hive_repository.dart';

/// Repository for managing project data
///
/// Provides CRUD operations for projects with additional business logic
/// for project management, status tracking, and client relationships.
class ProjectRepository extends HiveRepository<Project> {
  @override
  String get boxName => 'projects';

  /// Get projects sorted by deadline (soonest first)
  Future<List<Project>> getProjectsSortedByDeadline() async {
    final projects = await getAllOnce();
    projects.sort((a, b) => a.deadline.compareTo(b.deadline));
    return projects;
  }

  /// Get projects by status
  Future<List<Project>> getProjectsByStatus(String status) async {
    final projects = await getAllOnce();
    return projects.where((project) => project.status == status).toList();
  }

  /// Get projects for a specific client
  Future<List<Project>> getProjectsForClient(String clientId) async {
    final projects = await getAllOnce();
    return projects.where((project) => project.clientId == clientId).toList();
  }

  /// Get overdue projects
  Future<List<Project>> getOverdueProjects() async {
    final projects = await getAllOnce();
    final now = DateTime.now();
    return projects.where((project) =>
        project.deadline.isBefore(now) &&
        project.status != 'Completed'
    ).toList();
  }

  /// Get projects due soon (within next 7 days)
  Future<List<Project>> getProjectsDueSoon({int days = 7}) async {
    final projects = await getAllOnce();
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));

    return projects.where((project) =>
        project.deadline.isAfter(now) &&
        project.deadline.isBefore(futureDate) &&
        project.status != 'Completed'
    ).toList();
  }

  /// Update project status
  Future<void> updateProjectStatus(String projectId, String newStatus) async {
    final project = await getById(projectId);
    if (project != null) {
      final updatedProject = Project(
        id: project.id,
        name: project.name,
        clientName: project.clientName,
        clientId: project.clientId,
        budget: project.budget,
        deadline: project.deadline,
        status: newStatus,
        currency: project.currency,
      );
      await save(updatedProject);
    }
  }

  /// Get project statistics
  Future<ProjectStats> getProjectStats() async {
    final projects = await getAllOnce();
    final taskBox = Hive.box<TaskItem>('tasks');
    final invoiceBox = Hive.box<Invoice>('invoices');

    int totalTasks = 0;
    double totalBudget = 0.0;
    double totalInvoiced = 0.0;

    final statusCounts = <String, int>{};
    final overdueProjects = <Project>[];

    final now = DateTime.now();

    for (final project in projects) {
      totalBudget += project.budget;

      // Count tasks for this project
      final projectTasks = taskBox.values
          .where((task) => task.projectId == project.id)
          .toList();
      totalTasks += projectTasks.length;

      // Count invoices for this project
      final projectInvoices = invoiceBox.values
          .where((invoice) => invoice.projectId == project.id)
          .toList();

      for (final invoice in projectInvoices) {
        totalInvoiced += invoice.amount;
      }

      // Count by status
      statusCounts[project.status] = (statusCounts[project.status] ?? 0) + 1;

      // Check if overdue
      if (project.deadline.isBefore(now) && project.status != 'Completed') {
        overdueProjects.add(project);
      }
    }

    return ProjectStats(
      totalProjects: projects.length,
      totalTasks: totalTasks,
      totalBudget: totalBudget,
      totalInvoiced: totalInvoiced,
      statusCounts: statusCounts,
      overdueProjects: overdueProjects,
    );
  }

  /// Search projects by name, client, or status
  @override
  Future<List<Project>> search(String query) async {
    final allProjects = await getAllOnce();
    final lowercaseQuery = query.toLowerCase();

    return allProjects.where((project) {
      return project.name.toLowerCase().contains(lowercaseQuery) ||
             project.clientName.toLowerCase().contains(lowercaseQuery) ||
             project.status.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}

/// Statistics for project data
class ProjectStats {
  final int totalProjects;
  final int totalTasks;
  final double totalBudget;
  final double totalInvoiced;
  final Map<String, int> statusCounts;
  final List<Project> overdueProjects;

  const ProjectStats({
    required this.totalProjects,
    required this.totalTasks,
    required this.totalBudget,
    required this.totalInvoiced,
    required this.statusCounts,
    required this.overdueProjects,
  });

  double get completionRate {
    if (totalProjects == 0) return 0.0;
    final completed = statusCounts['Completed'] ?? 0;
    return completed / totalProjects;
  }

  double get budgetUtilization {
    if (totalBudget == 0) return 0.0;
    return totalInvoiced / totalBudget;
  }

  int get overdueCount => overdueProjects.length;
}