import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../screens/clients_screen.dart';
import '../screens/projects_screen.dart';
import '../services/haptic_service.dart';
import '../widgets/app_card.dart';

class CommandSearch extends StatefulWidget {
  const CommandSearch({super.key});

  @override
  State<CommandSearch> createState() => _CommandSearchState();
}

class _CommandSearchState extends State<CommandSearch> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    final List<dynamic> matches = [];

    // Search Clients
    final clientBox = Hive.box<Client>('clients');
    matches.addAll(clientBox.values.where((c) => 
      c.name.toLowerCase().contains(lowercaseQuery) || 
      c.company.toLowerCase().contains(lowercaseQuery)
    ));

    // Search Projects
    final projectBox = Hive.box<Project>('projects');
    matches.addAll(projectBox.values.where((p) => 
      p.name.toLowerCase().contains(lowercaseQuery) || 
      p.clientName.toLowerCase().contains(lowercaseQuery)
    ));

    // Search Invoices
    final invoiceBox = Hive.box<Invoice>('invoices');
    matches.addAll(invoiceBox.values.where((i) => 
      i.clientName.toLowerCase().contains(lowercaseQuery) || 
      i.id.toLowerCase().contains(lowercaseQuery)
    ));

    setState(() => _results = matches);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.search, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _performSearch,
                  style: GoogleFonts.poppins(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'Search anything...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              )
            ],
          ),
          const Divider(),
          Expanded(
            child: _results.isEmpty 
              ? _buildEmptyState() 
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return _buildResultTile(item);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.manage_search_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? 'Type to find clients, projects, or invoices' : 'No matches found',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(dynamic item) {
    IconData icon = Icons.help_outline;
    String title = '';
    String subtitle = '';
    Color color = Colors.grey;

    if (item is Client) {
      icon = Icons.person_outline;
      title = item.name;
      subtitle = 'Client • ${item.company}';
      color = Colors.green;
    } else if (item is Project) {
      icon = Icons.folder_outlined;
      title = item.name;
      subtitle = 'Project • ${item.clientName}';
      color = Colors.blue;
    } else if (item is Invoice) {
      icon = Icons.description_outlined;
      title = 'Invoice #${item.id.substring(0, 8)}';
      subtitle = 'Invoice • ${item.clientName} • \$${item.amount.toInt()}';
      color = Colors.orange;
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        HapticService.light();
        // Navigate directly to the relevant screen for the selected result
        Navigator.pop(context);

        if (item is Client) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClientsScreen()),
          );
        } else if (item is Project) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProjectsScreen()),
          );
        } else if (item is Invoice) {
          // For now, just show where the invoice belongs (client page)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClientsScreen()),
          );
        }
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}
