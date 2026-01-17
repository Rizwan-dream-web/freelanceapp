import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../repositories/repository_manager.dart';
import '../services/currency_service.dart';
import '../constants/app_constants.dart';
import 'glass_container.dart';

class ClientHistorySheet extends StatelessWidget {
  final Client client;

  const ClientHistorySheet({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        client.company.isNotEmpty ? client.company : 'Individual Client',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Content
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                   TabBar(
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                    unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(text: 'Invoices'),
                      Tab(text: 'Projects'),
                      Tab(text: 'Proposals'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildInvoiceList(),
                        _buildProjectList(),
                        _buildProposalList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceList() {
    return StreamBuilder<List<Invoice>>(
      stream: repositoryManager.invoices.getAll(),
      builder: (context, snapshot) {
        final clientInvoices = snapshot.data?.where((i) => i.clientName.toLowerCase() == client.name.toLowerCase()).toList() ?? [];
        
        if (clientInvoices.isEmpty) return _buildEmptyState(context, 'No invoices found');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: clientInvoices.length,
          itemBuilder: (context, index) {
            final invoice = clientInvoices[index];
            final statusColor = invoice.status == InvoiceStatus.paid ? Colors.green : Colors.orange;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.receipt_long, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invoice #${invoice.id.substring(0, 5).toUpperCase()}', 
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(DateFormat('dd MMM yyyy').format(invoice.date), 
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(CurrencyService.format(invoice.amount, invoice.currency), 
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(invoice.status.toUpperCase(), 
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProjectList() {
     return StreamBuilder<List<Project>>(
      stream: repositoryManager.projects.getAll(),
      builder: (context, snapshot) {
        final clientProjects = snapshot.data?.where((p) => p.clientName.toLowerCase() == client.name.toLowerCase()).toList() ?? [];
        
        if (clientProjects.isEmpty) return _buildEmptyState(context, 'No projects found');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: clientProjects.length,
          itemBuilder: (context, index) {
            final project = clientProjects[index];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.name, 
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Deadline: ${DateFormat('dd MMM yyyy').format(project.deadline)}', 
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(project.status.toUpperCase(), 
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProposalList() {
     return StreamBuilder<List<Proposal>>(
      stream: repositoryManager.proposals.getAll(),
      builder: (context, snapshot) {
        final clientProposals = snapshot.data?.where((p) => p.clientName.toLowerCase() == client.name.toLowerCase()).toList() ?? [];
        
        if (clientProposals.isEmpty) return _buildEmptyState(context, 'No proposals found');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: clientProposals.length,
          itemBuilder: (context, index) {
            final proposal = clientProposals[index];
            Color statusColor = Colors.grey;
            if (proposal.status == 'Accepted') statusColor = Colors.green;
            if (proposal.status == 'Rejected') statusColor = Colors.red;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.description_outlined, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(proposal.projectTitle, 
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(DateFormat('dd MMM yyyy').format(proposal.dateSent), 
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(proposal.status.toUpperCase(), 
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(message, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
