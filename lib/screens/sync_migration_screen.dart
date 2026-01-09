import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sync_service.dart';

class SyncMigrationScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SyncMigrationScreen({super.key, required this.onComplete});

  @override
  State<SyncMigrationScreen> createState() => _SyncMigrationScreenState();
}

class _SyncMigrationScreenState extends State<SyncMigrationScreen> {
  final SyncService _sync = SyncService();
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _startMigration();
  }

  Future<void> _startMigration() async {
    try {
      await Future.delayed(const Duration(seconds: 2)); // Calm delay for UX
      await _sync.performInitialMigration();
      widget.onComplete();
    } catch (e) {
      setState(() => _isError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isError) ...[
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 24),
                Text(
                  'Connection interrupted',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'We couldn’t connect. Please check your signal and try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => setState(() {
                    _isError = false;
                    _startMigration();
                  }),
                  child: const Text('Try Again'),
                ),
              ] else ...[
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 4),
                  builder: (context, value, child) {
                    return Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: CircularProgressIndicator(
                        value: value < 0.9 ? null : 1.0, // Indeterminate then full
                        strokeWidth: 3,
                        color: primaryColor,
                        backgroundColor: primaryColor.withOpacity(0.1),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  'Securing your data...',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Almost ready to enter your command center.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
