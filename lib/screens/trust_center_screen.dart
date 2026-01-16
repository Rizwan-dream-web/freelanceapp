import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../repositories/repository_manager.dart';
import '../widgets/app_card.dart';
import '../services/haptic_service.dart';

class TrustCenterScreen extends StatelessWidget {
  const TrustCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trust & Privacy', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShieldHeader(context),
            const SizedBox(height: 32),
            _buildSectionTitle('DATA PROTECTION'),
            const SizedBox(height: 16),
            _buildStatusCard(
              context,
              'AES-256 Encryption',
              'Your data is encrypted locally on this device.',
              Icons.enhanced_encryption_outlined,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildStatusCard(
              context,
              'Offline-First Architecture',
              'No data leaves your device unless you choose to sync.',
              Icons.cloud_off_outlined,
              Colors.blue,
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('SYNC & BACKUP'),
            const SizedBox(height: 16),
            _buildBackupStats(context),
            const SizedBox(height: 32),
            _buildSectionTitle('TRANSPARENCY'),
            const SizedBox(height: 16),
            _buildStatusCard(
              context,
              'Zero Tracking',
              'We do not use analytics or track your usage patterns.',
              Icons.visibility_off_outlined,
              Colors.purple,
            ),
            const SizedBox(height: 48),
            Center(
              child: Text(
                'Version 1.5.0 - Protected by Antigravity Core',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildShieldHeader(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your Data is Safe',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Locally stored. Privately encrypted.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupStats(BuildContext context) {
    final lastSync = repositoryManager.settings.get('lastSyncTime');
    final syncType = repositoryManager.settings.get('isCloudMigrated', defaultValue: false) ? 'Cloud Sync' : 'Local Only';

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildStatRow('Sync Mode', syncType),
          const Divider(height: 24),
          _buildStatRow('Last Backup', lastSync != null ? DateFormat.yMMMd().add_jm().format(DateTime.parse(lastSync)) : 'Never'),
          const Divider(height: 24),
          _buildStatRow('Data Health', 'Optimized'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
