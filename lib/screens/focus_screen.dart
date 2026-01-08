import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class FocusScreen extends StatefulWidget {
  final TaskItem task;

  const FocusScreen({super.key, required this.task});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with TickerProviderStateMixin {
  late Timer _timer;
  late Duration _currentDuration;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.task.isRunning && !_isPaused) {
        setState(() {
          _updateDuration();
        });
      }
    });
  }

  void _updateDuration() {
    final lastStart = widget.task.lastStartTime;
    final elapsed = lastStart != null 
        ? DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastStart)).inSeconds 
        : 0;
    _currentDuration = Duration(seconds: widget.task.totalSeconds + elapsed);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      // In a real app, we'd update the DB state here to stop "accumulating" time while paused, 
      // but for this MVP, visual pause is enough or we rely on the main Stop logic.
      // Actually, to be accurate, if we pause, we should stop the DB timer.
      if (_isPaused) {
        _stopDbTimer();
      } else {
        _startDbTimer();
      }
    });
  }

  void _stopDbTimer() {
    if (widget.task.isRunning) {
       final now = DateTime.now();
       final start = DateTime.fromMillisecondsSinceEpoch(widget.task.lastStartTime!);
       widget.task.totalSeconds += now.difference(start).inSeconds;
       widget.task.isRunning = false;
       widget.task.lastStartTime = null;
       widget.task.save();
    }
  }

  void _startDbTimer() {
    if (!widget.task.isRunning) {
      widget.task.isRunning = true;
      widget.task.lastStartTime = DateTime.now().millisecondsSinceEpoch;
      widget.task.save();
    }
  }

  void _finishTask() {
    _stopDbTimer();
    widget.task.isCompleted = true;
    widget.task.save();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Zen Mode UI
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient (Subtle)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF1a1a1a), Color(0xFF000000)],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            const Icon(Icons.spa, color: Colors.white70, size: 14),
                            const SizedBox(width: 6),
                            Text('ZEN MODE', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, letterSpacing: 1.5)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40), // Balance
                    ],
                  ),
                ),
                
                const Spacer(),

                // Timer & Task
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: Hive.box<Project>('projects').listenable(),
                      builder: (context, Box<Project> projectBox, _) {
                        final project = projectBox.values.firstWhere((p) => p.id == widget.task.projectId, orElse: () => Project(id: '', name: 'Unknown', clientName: '', budget: 0, deadline: DateTime.now()));
                        return Text(
                          project.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.task.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'FOCUSING...',
                      style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 12, letterSpacing: 4),
                    ),
                    const SizedBox(height: 50),
                    
                    // Huge Timer
                    Text(
                      '${_currentDuration.inHours.toString().padLeft(2,'0')}:${(_currentDuration.inMinutes%60).toString().padLeft(2,'0')}:${(_currentDuration.inSeconds%60).toString().padLeft(2,'0')}',
                      style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const Spacer(),

                // Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlBtn(
                        icon: _isPaused || !widget.task.isRunning ? Icons.play_arrow : Icons.pause,
                        color: _isPaused || !widget.task.isRunning ? Colors.green : Colors.orange,
                        onTap: _togglePause,
                      ),
                      const SizedBox(width: 30),
                      _buildControlBtn(
                        icon: Icons.check,
                        color: Colors.blue,
                        onTap: _finishTask,
                        size: 80,
                      ),
                      const SizedBox(width: 30),
                      _buildControlBtn(
                        icon: Icons.stop,
                        color: Colors.red,
                        onTap: () {
                           _stopDbTimer();
                           Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBtn({required IconData icon, required Color color, required VoidCallback onTap, double size = 60}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
