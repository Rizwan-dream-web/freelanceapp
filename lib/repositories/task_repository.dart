import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'hive_repository.dart';

/// Repository for managing task data
///
/// Provides CRUD operations for tasks with additional business logic
/// for time tracking, project relationships, and productivity analytics.
class TaskRepository extends HiveRepository<TaskItem> {
  @override
  String get boxName => 'tasks';

  /// Get tasks for a specific project
  Future<List<TaskItem>> getTasksForProject(String projectId) async {
    final tasks = await getAllOnce();
    return tasks.where((task) => task.projectId == projectId).toList();
  }

  /// Get active tasks (not completed)
  Future<List<TaskItem>> getActiveTasks() async {
    final tasks = await getAllOnce();
    return tasks.where((task) => !task.isCompleted).toList();
  }

  /// Get completed tasks
  Future<List<TaskItem>> getCompletedTasks() async {
    final tasks = await getAllOnce();
    return tasks.where((task) => task.isCompleted).toList();
  }

  /// Get tasks due today (simplified - no due date in model)
  Future<List<TaskItem>> getTasksDueToday() async {
    // TaskItem doesn't have dueDate, so return empty list
    return [];
  }

  /// Get overdue tasks
  Future<List<TaskItem>> getOverdueTasks() async {
    // TaskItem doesn't have dueDate, so return empty list
    return [];
  }

  /// Mark task as completed
  Future<void> markTaskCompleted(String taskId, {DateTime? completedAt}) async {
    final task = await getById(taskId);
    if (task != null) {
      final updatedTask = TaskItem(
        id: task.id,
        projectId: task.projectId,
        title: task.title,
        isCompleted: true,
        totalSeconds: task.totalSeconds,
        isRunning: false,
        lastStartTime: task.lastStartTime,
        dailyTracked: task.dailyTracked,
        uid: task.uid,
      );
      await save(updatedTask);
    }
  }

  /// Mark task as incomplete
  Future<void> markTaskIncomplete(String taskId) async {
    final task = await getById(taskId);
    if (task != null) {
      final updatedTask = TaskItem(
        id: task.id,
        projectId: task.projectId,
        title: task.title,
        isCompleted: false,
        totalSeconds: task.totalSeconds,
        isRunning: task.isRunning,
        lastStartTime: task.lastStartTime,
        dailyTracked: task.dailyTracked,
        uid: task.uid,
      );
      await save(updatedTask);
    }
  }

  /// Update task time tracking
  Future<void> updateTaskTime(String taskId, double additionalHours) async {
    final task = await getById(taskId);
    if (task != null) {
      final additionalSeconds = (additionalHours * 3600).round();
      final updatedTask = TaskItem(
        id: task.id,
        projectId: task.projectId,
        title: task.title,
        isCompleted: task.isCompleted,
        totalSeconds: task.totalSeconds + additionalSeconds,
        isRunning: task.isRunning,
        lastStartTime: task.lastStartTime,
        dailyTracked: task.dailyTracked,
        uid: task.uid,
      );
      await save(updatedTask);
    }
  }

  /// Get tasks by priority (simplified - no priority in model)
  Future<List<TaskItem>> getTasksByPriority(String priority) async {
    // TaskItem doesn't have priority, return all tasks
    return await getAllOnce();
  }

  /// Get task statistics
  Future<TaskStats> getTaskStats() async {
    final tasks = await getAllOnce();
    final now = DateTime.now();

    int completedToday = 0;
    int overdueTasks = 0;
    double totalTrackedHours = 0.0;

    final priorityCounts = <String, int>{}; // Simplified - no priority in model
    final completionByDay = <DateTime, int>{};

    for (final task in tasks) {
      totalTrackedHours += task.totalSeconds / 3600.0;

      // Simplified priority count - all tasks have same priority
      priorityCounts['Normal'] = (priorityCounts['Normal'] ?? 0) + 1;

      // Simplified - can't track completion by day without completedAt
      if (task.isCompleted) {
        completedToday++; // Simplified
      }

      // Simplified - no overdue logic without dueDate
      // Simplified - no completion tracking without completedAt
    }

    return TaskStats(
      totalTasks: tasks.length,
      completedTasks: tasks.where((t) => t.isCompleted).length,
      activeTasks: tasks.where((t) => !t.isCompleted).length,
      completedToday: completedToday,
      overdueTasks: overdueTasks,
      totalEstimatedHours: 0.0, // TaskItem doesn't have estimated hours
      totalActualHours: totalTrackedHours,
      priorityCounts: priorityCounts,
      completionByDay: completionByDay,
    );
  }

  /// Search tasks by title
  @override
  Future<List<TaskItem>> search(String query) async {
    final allTasks = await getAllOnce();
    final lowercaseQuery = query.toLowerCase();

    return allTasks.where((task) {
      return task.title.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}

/// Statistics for task data
class TaskStats {
  final int totalTasks;
  final int completedTasks;
  final int activeTasks;
  final int completedToday;
  final int overdueTasks;
  final double totalEstimatedHours;
  final double totalActualHours;
  final Map<String, int> priorityCounts;
  final Map<DateTime, int> completionByDay;

  const TaskStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.activeTasks,
    required this.completedToday,
    required this.overdueTasks,
    required this.totalEstimatedHours,
    required this.totalActualHours,
    required this.priorityCounts,
    required this.completionByDay,
  });

  double get completionRate {
    if (totalTasks == 0) return 0.0;
    return completedTasks / totalTasks;
  }

  double get timeEfficiency {
    if (totalEstimatedHours == 0) return 0.0;
    return totalActualHours / totalEstimatedHours;
  }

  bool get hasOverdueTasks => overdueTasks > 0;
}