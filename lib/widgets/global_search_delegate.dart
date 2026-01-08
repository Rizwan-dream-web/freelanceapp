import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../screens/clients_screen.dart'; // To show edit dialogs
import '../screens/projects_screen.dart';
import '../screens/proposals_screen.dart';

class GlobalSearchDelegate extends SearchDelegate {
  
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: Theme.of(context).appBarTheme.copyWith(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: Colors.grey[800]),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('Search clients, projects, invoices...', style: GoogleFonts.poppins(color: Colors.grey[500])),
          ],
        ),
      );
    }

    // 1. Search Query Logic
    final lowerQuery = query.toLowerCase();

    // Data Sources
    final projects = Hive.box<Project>('projects').values.where((p) => p.name.toLowerCase().contains(lowerQuery) || p.clientName.toLowerCase().contains(lowerQuery));
    final clients = Hive.box<Client>('clients').values.where((c) => c.name.toLowerCase().contains(lowerQuery) || c.company.toLowerCase().contains(lowerQuery));
    final invoices = Hive.box<Invoice>('invoices').values.where((i) => i.clientName.toLowerCase().contains(lowerQuery) || i.id.toLowerCase().contains(lowerQuery));
    final proposals = Hive.box<Proposal>('proposals').values.where((p) => p.projectTitle.toLowerCase().contains(lowerQuery) || p.clientName.toLowerCase().contains(lowerQuery));

    List<Widget> results = [];

    // 2. Build Result List
    if (clients.isNotEmpty) {
      results.add(_buildHeader('Clients'));
      results.addAll(clients.map((c) => ListTile(
        leading: CircleAvatar(backgroundColor: Colors.blue[100], child: Text(c.name[0], style: const TextStyle(color: Colors.blue))),
        title: Text(c.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(c.company, style: GoogleFonts.poppins(fontSize: 12)),
        onTap: () {
          // close(context, null); // Optional: keep search open? No, usually close.
           // How to open details? We need to navigate or show dialog.
           // Since dialogs are local to screens, it's tricky. 
           // Best effort: Show a simple generic detail or try to re-use screen dialogs if public.
           // For now, let's just close and show a SnackBar or navigateto relevant tab.
           // Ideally, we'd navigate to the detailed screen.
        },
      )));
    }

    if (projects.isNotEmpty) {
      results.add(_buildHeader('Projects'));
      results.addAll(projects.map((p) => ListTile(
        leading: const Icon(Icons.folder, color: Colors.orange),
        title: Text(p.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(p.status, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        trailing: Text(DateFormat.MMMd().format(p.deadline), style: GoogleFonts.poppins(fontSize: 11)),
      )));
    }

    if (invoices.isNotEmpty) {
      results.add(_buildHeader('Invoices'));
      results.addAll(invoices.map((i) => ListTile(
        leading: const Icon(Icons.receipt_long, color: Colors.green),
        title: Text('\$${i.amount.toStringAsFixed(0)} - ${i.clientName}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text('#${i.id.substring(0,6)}', style: GoogleFonts.poppins(fontSize: 12)),
        trailing: Text(i.status, style: GoogleFonts.poppins(color: i.status == 'Paid' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
      )));
    }

    if (proposals.isNotEmpty) {
      results.add(_buildHeader('Proposals'));
      results.addAll(proposals.map((p) => ListTile(
        leading: const Icon(Icons.description, color: Colors.purple),
        title: Text(p.projectTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(p.clientName, style: GoogleFonts.poppins(fontSize: 12)),
      )));
    }

    if (results.isEmpty) {
      return Center(child: Text('No results found', style: GoogleFonts.poppins(color: Colors.grey)));
    }

    return ListView(children: results);
  }

  Widget _buildHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.grey[50],
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2),
      ),
    );
  }
}
