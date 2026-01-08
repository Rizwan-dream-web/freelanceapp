import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'package:uuid/uuid.dart';
import '../services/currency_service.dart';
import 'focus_screen.dart';

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
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Colors.white,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor ?? Colors.black,
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
                  // --- Productivity Header ---
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF66BB6A)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TOTAL TRACKED', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
                            const SizedBox(height: 5),
                            Text('${hours}h ${minutes}m', style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.bar_chart, color: Colors.white, size: 30),
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
                        final cardColor = task.isCompleted 
                            ? (isDark ? Colors.grey[900] : Colors.grey[50]) 
                            : Theme.of(context).cardColor;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: task.isRunning ? 6 : 2,
                          shadowColor: task.isRunning ? Colors.blue.withOpacity(0.3) : Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: task.isRunning ? const BorderSide(color: Colors.blue, width: 1.5) : BorderSide.none
                          ),
                          color: cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ListTile(
                              leading: Checkbox(
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
                              title: Text(
                                project.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                task.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  color: task.isCompleted ? Colors.grey : Colors.grey[600],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!task.isCompleted) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: task.isRunning ? Colors.blue[50] : (isDark ? Colors.grey[800] : Colors.grey[100]),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        formattedTime,
                                        style: GoogleFonts.monoton( 
                                          fontSize: 13, 
                                          fontWeight: FontWeight.bold,
                                          color: task.isRunning ? Colors.blue : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        task.isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                        color: task.isRunning ? Colors.orange : Colors.green,
                                        size: 32,
                                      ),
                                      onPressed: () => _toggleTimer(task, taskBox),
                                    ),
                                  ] else ...[
                                     Text(formattedTime, style: const TextStyle(color: Colors.grey)),
                                  ],
                                  PopupMenuButton(
                                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                                    onSelected: (val) {
                                      if (val == 'delete') {
                                        taskBox.delete(task.id);
                                      } else if (val == 'focus') {
                                        if (!task.isRunning) {
                                          task.isRunning = true;
                                          task.lastStartTime = DateTime.now().millisecondsSinceEpoch;
                                          task.save();
                                        }
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => FocusScreen(task: task)));
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'focus', child: Text('Focus Mode')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
