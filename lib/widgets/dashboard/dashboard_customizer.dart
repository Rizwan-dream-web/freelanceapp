import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../repositories/repository_manager.dart';
import '../../services/haptic_service.dart';

class DashboardCustomizer extends StatefulWidget {
  const DashboardCustomizer({super.key});

  @override
  State<DashboardCustomizer> createState() => _DashboardCustomizerState();
}

class _DashboardCustomizerState extends State<DashboardCustomizer> {
  late Map<String, bool> _visibility;

  @override
  void initState() {
    super.initState();
    final savedVisibility = repositoryManager.settings.get('dashboard_visibility', defaultValue: <String, bool>{});
    _visibility = {
      'daily_effort': savedVisibility['daily_effort'] ?? true,
      'daily_focus': savedVisibility['daily_focus'] ?? true,
      'smart_insights': savedVisibility['smart_insights'] ?? true,
      'time_burn': savedVisibility['time_burn'] ?? true,
      'financial_snapshot': savedVisibility['financial_snapshot'] ?? true,
      'quick_actions': savedVisibility['quick_actions'] ?? true,
    };
  }

  void _toggle(String key, bool value) {
    HapticService.light();
    setState(() => _visibility[key] = value);
    repositoryManager.settings.set('dashboard_visibility', _visibility);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personalize Dashboard',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Toggle widgets to build your ideal workspace.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildItem('Daily Effort Chart', 'daily_effort', Icons.bar_chart_outlined),
          _buildItem('Daily Focus Project', 'daily_focus', Icons.star_outline),
          _buildItem('Smart Insights', 'smart_insights', Icons.auto_awesome_outlined),
          _buildItem('Time Burn Card', 'time_burn', Icons.timer_outlined),
          _buildItem('Financial Snapshot', 'financial_snapshot', Icons.payments_outlined),
          _buildItem('Quick Actions', 'quick_actions', Icons.bolt_outlined),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Apply Changes',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildItem(String label, String key, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile.adaptive(
        value: _visibility[key]!,
        onChanged: (val) => _toggle(key, val),
        title: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
        contentPadding: EdgeInsets.zero,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
