import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/security_service.dart';
import '../services/haptic_service.dart';
import '../widgets/app_card.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportBackup() async {
    HapticService.light();
    setState(() => _isExporting = true);
    
    try {
      final json = await SecurityService.generateBackupJson();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(json);
      
      HapticService.success();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup saved to: $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      HapticService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _importBackup() async {
    HapticService.medium();
    
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Restore Data?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text('This will overwrite all current data. This action cannot be undone.', style: GoogleFonts.poppins()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Confirm Restore'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isImporting = true);
        try {
          final file = File(result.files.single.path!);
          final json = await file.readAsString();
          await SecurityService.restoreFromJson(json);
          
          HapticService.success();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data restored successfully!'), backgroundColor: Colors.green),
          );
        } catch (e) {
          HapticService.error();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
          );
        } finally {
          setState(() => _isImporting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trust & Control', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          Text(
            'ACTIONS',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            onTap: _isExporting ? null : _exportBackup,
            child: Row(
              children: [
                _iconBox(Icons.cloud_upload_outlined, Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create Snapshot', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Export encrypted business data', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                if (_isExporting)
                  const CircularProgressIndicator(strokeWidth: 2)
                else
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
          AppCard(
            onTap: _isImporting ? null : _importBackup,
            child: Row(
              children: [
                _iconBox(Icons.settings_backup_restore_rounded, Colors.orange),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Restore Point', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Import data from a backup file', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                if (_isImporting)
                  const CircularProgressIndicator(strokeWidth: 2)
                else
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildFreedomModelCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: Colors.white, size: 32),
          const SizedBox(height: 16),
          Text(
            'Your data is private & localized.',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'We use AES-256 equivalent logic to ensure your business stays yours. Always keep a backup before clearing cache.',
            style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFreedomModelCard() {
    return AppCard(
      color: Colors.green.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'FREEDOM MODEL (v3.0)',
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Full Agency Features Active', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('You are running the 100% Free, Private-First edition.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
