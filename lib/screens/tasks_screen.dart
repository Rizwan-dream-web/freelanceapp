import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'package:uuid/uuid.dart';
import '../services/currency_service.dart';
import 'focus_screen.dart';
import '../widgets/app_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Tasks & Time', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<TaskItem>('tasks').listenable(),
        builder: (context, Box<TaskItem> taskBox, _) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<Project>('projects').listenable(),
            builder: (context, Box<Project> projectBox, _) {
              if (taskBox.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No tasks yet', style: GoogleFonts.poppins(color: Colors.grey[500])),
                    ],
                  ),
                );
              }
              
              final tasks = taskBox.values.toList().cast<TaskItem>();
              tasks.sort((a, b) {
                if (a.isRunning && !b.isRunning) return -1;
                if (!a.isRunning && b.isRunning) return 1;
                if (!a.isCompleted && b.isCompleted) return -1;
                if (a.isCompleted && !b.isCompleted) return 1;
                return 0;
              });

              // --- Logic for Daily Summary ---
              int totalSecondsToday = 0;
              final nowMs = DateTime.now().millisecondsSinceEpoch;
              for (var t in tasks) {
                 totalSecondsToday += t.totalSeconds;
                 if (t.isRunning && t.lastStartTime != null) {
                   totalSecondsToday += ((nowMs - t.lastStartTime!) / 1000).floor();
                 }
              }
              final hours = totalSecondsToday ~/ 3600;
              final minutes = (totalSecondsToday % 3600) ~/ 60;

              return Column(
                children: [
                  // --- Productivity Header (Premium Refinement) ---
                  AppCard(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    color: Theme.of(context).colorScheme.primary,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL TRACKED TODAY', 
                              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${hours}h ${minutes}m', 
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: Icon(Icons.timer_outlined, color: Colors.white.withOpacity(0.9), size: 28),
                        )
                      ],
                    ),
                  ),

                  // --- Task List ---
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final project = projectBox.values.firstWhere(
                          (p) => p.id == task.projectId, 
                          orElse: () => Project(id: '', name: 'Unknown Project', clientName: '', budget: 0, deadline: DateTime.now())
                        );

                        int currentSeconds = task.totalSeconds;
                        if (task.isRunning && task.lastStartTime != null) {
                          final now = DateTime.now().millisecondsSinceEpoch;
                          final elapsed = ((now - task.lastStartTime!) / 1000).floor();
                          currentSeconds += elapsed;
                        }
                        final formattedTime = _formatDuration(currentSeconds);
                        
                        final isDark = Theme.of(context).brightness == Brightness.dark;

                        return AppCard(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: task.isCompleted,
                                      activeColor: Colors.grey,
                                      onChanged: (val) {
                                        task.isCompleted = val ?? false;
                                        if (task.isCompleted && task.isRunning) {
                                          _toggleTimer(task, taskBox);
                                        }
                                        taskBox.put(task.id, task);
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                              color: task.isCompleted ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                                            ),
                                          ),
                                          Text(
                                            project.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Timer Controls
                                    if (!task.isCompleted)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            formattedTime,
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: task.isRunning ? Theme.of(context).colorScheme.primary : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () => _toggleTimer(task, taskBox),
                                            icon: Icon(
                                              task.isRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                              color: task.isRunning ? Colors.orange : Theme.of(context).colorScheme.primary,
                                              size: 34,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(formattedTime, style: GoogleFonts.jetBrainsMono(color: Colors.grey, fontSize: 13, decoration: TextDecoration.lineThrough)),
                                  ],
                                ),
                              ),
                              // Footer Magic Actions
                              Container(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!task.isCompleted)
                                      TextButton.icon(
                                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FocusScreen(task: task))),
                                        icon: const Icon(Icons.center_focus_strong_outlined, size: 16),
                                        label: Text('Focus', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                                      ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                      onPressed: () => taskBox.delete(task.id),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );

            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _toggleTimer(TaskItem task, Box<TaskItem> box) {
    if (task.isRunning) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = ((now - task.lastStartTime!) / 1000).floor();
      task.totalSeconds += elapsed;
      task.isRunning = false;
      task.lastStartTime = null;
    } else {
      task.isRunning = true;
      task.lastStartTime = DateTime.now().millisecondsSinceEpoch;
    }
    box.put(task.id, task);
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );
  }
}

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String? _selectedProjectId;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedProjectId != null) {
      final box = Hive.box<TaskItem>('tasks');
      final id = const Uuid().v4();
      final newTask = TaskItem(
        id: id,
        projectId: _selectedProjectId!,
        title: _titleController.text,
      );
      box.put(id, newTask);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectBox = Hive.box<Project>('projects');
    final projects = projectBox.values.toList().cast<Project>();
    projects.sort((a,b) {
        if (a.status != 'Completed' && b.status == 'Completed') return -1;
        if (a.status == 'Completed' && b.status != 'Completed') return 1;
        return a.name.compareTo(b.name);
    });

    if (projects.isEmpty) {
      return AlertDialog(
        title: const Text('No Projects'),
        content: const Text('You need to create a project first.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      );
    }

    return AlertDialog(
      title: Text('New Task', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      backgroundColor: Theme.of(context).cardColor, 
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedProjectId,
              hint: const Text('Select Project'),
              items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
              onChanged: (v) => setState(() => _selectedProjectId = v),
              validator: (v) => v == null ? 'Required' : null,
              dropdownColor: Theme.of(context).cardColor,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task Title'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Add')),
      ],
    );
  }
}
