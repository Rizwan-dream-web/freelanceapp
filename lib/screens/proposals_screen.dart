import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/proposal_pdf_generator.dart';
import '../services/haptic_service.dart';
import '../widgets/app_card.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ProposalsScreen extends StatelessWidget {
  const ProposalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Proposals', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          bottom: TabBar(
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.poppins(),
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Accepted'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: ValueListenableBuilder(
          valueListenable: Hive.box<Proposal>('proposals').listenable(),
          builder: (context, Box<Proposal> box, _) {
            final proposals = box.values.toList().cast<Proposal>();
            proposals.sort((a, b) => b.dateSent.compareTo(a.dateSent));

            return TabBarView(
              children: [
                _buildProposalList(context, proposals.where((p) => p.status == 'Pending').toList()),
                _buildProposalList(context, proposals.where((p) => p.status == 'Accepted').toList()),
                _buildProposalList(context, proposals.where((p) => p.status == 'Rejected').toList()),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEditDialog(context),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProposalList(BuildContext context, List<Proposal> proposals) {
    if (proposals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No proposals here', style: GoogleFonts.poppins(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: proposals.length,
      itemBuilder: (context, index) {
        final proposal = proposals[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AppCard(
          margin: const EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.zero,
          onTap: () => _showAddEditDialog(context, proposal: proposal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                proposal.projectTitle,
                                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                proposal.clientName,
                                style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        _statusBadge(context, proposal.status),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat.yMMMd().format(proposal.dateSent),
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                        ),
                        const Spacer(),
                        Text(
                          '\$${proposal.estimatedBudget.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Footer Magic Actions
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => ProposalPdfGenerator.generateAndShow(proposal),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: Text('View', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white70 : Colors.black87),
                    ),
                    TextButton.icon(
                      onPressed: () => _shareProposal(proposal),
                      icon: const Icon(Icons.share_outlined, size: 16),
                      label: Text('Share', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white70 : Colors.black87),
                    ),
                    const Spacer(),
                    if (proposal.status != 'Rejected')
                      ElevatedButton.icon(
                        onPressed: () => _convertToProject(context, proposal),
                        icon: const Icon(Icons.rocket_launch_rounded, size: 14),
                        label: Text('CONVERT', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  void _convertToProject(BuildContext context, Proposal proposal) {
      // 1. Create Project
      final projectBox = Hive.box<Project>('projects');
      final newProjectId = const Uuid().v4();
      final newProject = Project(
        id: newProjectId,
        name: proposal.projectTitle,
        clientName: proposal.clientName,
        budget: proposal.estimatedBudget,
        deadline: DateTime.now().add(const Duration(days: 14)), // Default 2 weeks
        status: 'Not Started',
        estimatedHours: (proposal.estimatedBudget / 50).round(), // Smart guess: $50/hr
      );
      projectBox.put(newProjectId, newProject);

      // 2. Update Proposal Status
      if (proposal.status != 'Accepted') {
        HapticService.success();
        proposal.status = 'Accepted';
        proposal.save();
      }

      // 3. Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project created from proposal!', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
               // Navigation to projects tab? 
               // For now just stay here contextually or maybe switch tab in MainContainer 
               // (Requires access to MainContainer state which is hard here).
            },
          ),
        ),
      );
  }

  Future<void> _shareProposal(Proposal proposal) async {
    HapticService.light();
    try {
      final bytes = await ProposalPdfGenerator.generatePdf(proposal);
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/proposal_${proposal.id.substring(0, 8)}.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(path)],
        text: 'Proposal: ${proposal.projectTitle} for ${proposal.clientName}',
        subject: 'Business Proposal: ${proposal.projectTitle}',
      );
    } catch (e) {
      // Intentionally silent or handled via snackbar
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Accepted': return Colors.green;
      case 'Rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  void _showAddEditDialog(BuildContext context, {Proposal? proposal}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
         bottom: MediaQuery.of(context).viewInsets.bottom,
       ),
       child: ProposalForm(proposal: proposal),
      ),
    );
  }
}

class ProposalForm extends StatefulWidget {
  final Proposal? proposal;

  const ProposalForm({super.key, this.proposal});

  @override
  State<ProposalForm> createState() => _ProposalFormState();
}

class _ProposalFormState extends State<ProposalForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clientController;
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _timelineController;
  late TextEditingController _budgetController;
  String _status = 'Pending';
  String _style = 'Corporate';
  
  @override
  void initState() {
    super.initState();
    _clientController = TextEditingController(text: widget.proposal?.clientName ?? '');
    _titleController = TextEditingController(text: widget.proposal?.projectTitle ?? '');
    _descController = TextEditingController(text: widget.proposal?.description ?? '');
    _timelineController = TextEditingController(text: widget.proposal?.timeline ?? '');
    _budgetController = TextEditingController(text: widget.proposal?.estimatedBudget.toString() ?? '');
    _status = widget.proposal?.status ?? 'Pending';
    _style = widget.proposal?.style ?? 'Corporate';
  }

  @override
  void dispose() {
    _clientController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _timelineController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _showTemplates() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Choose a Template', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        children: [
          SimpleDialogOption(
            padding: const EdgeInsets.all(16),
            onPressed: () {
              _descController.text = "I propose to design and develop a responsive, SEO-friendly website tailored to your brand identity. The site will be built using modern web technologies to ensure speed, security, and scalability.";
              _timelineController.text = "Phase 1: UI/UX Design (1 Week)\nPhase 2: Frontend Development (2 Weeks)\nPhase 3: Backend & SEO Integration (1 Week)\nPhase 4: Testing & Launch (3 Days)";
              Navigator.pop(context);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Web Development', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Text('Responsive, SEO-friendly site...', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          SimpleDialogOption(
            padding: const EdgeInsets.all(16),
            onPressed: () {
              _descController.text = "I propose to develop a high-performance, cross-platform mobile application using Flutter. This ensures a consistent user experience on both iOS and Android from a single codebase.";
              _timelineController.text = "Phase 1: Architecture & Design (1 Week)\nPhase 2: Core Feature Implementation (3 Weeks)\nPhase 3: Cross-platform API Integration (1 Week)\nPhase 4: Store Deployment Support (1 Week)";
              Navigator.pop(context);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mobile App (Flutter)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Text('Cross-platform iOS & Android...', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          SimpleDialogOption(
            padding: const EdgeInsets.all(16),
            onPressed: () {
              _descController.text = "I propose a comprehensive SEO audit followed by a content strategy to improve organic ranking. This includes keyword research, on-page optimization, and competitor analysis.";
              _timelineController.text = "Week 1: Audit & Keyword Research\nWeek 2: On-page Optimizations\nWeek 3: Content Creation & Backlink Strategy\nWeek 4: Performance Monitoring & Reporting";
              Navigator.pop(context);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SEO & Marketing', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Text('Audit, Keywords, Strategy...', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      HapticService.success();
      final box = Hive.box<Proposal>('proposals');
      final id = widget.proposal?.id ?? const Uuid().v4();
      final newProposal = Proposal(
        id: id,
        clientName: _clientController.text,
        projectTitle: _titleController.text,
        description: _descController.text,
        timeline: _timelineController.text,
        estimatedBudget: double.tryParse(_budgetController.text) ?? 0.0,
        dateSent: widget.proposal?.dateSent ?? DateTime.now(),
        status: _status,
        style: _style,
      );

      box.put(id, newProposal);
      
      Navigator.pop(context);
    }
  }

  void _delete() {
    if (widget.proposal != null) {
       HapticService.medium();
       final box = Hive.box<Proposal>('proposals');
       box.delete(widget.proposal!.id);
       Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
     return Padding(
       padding: const EdgeInsets.all(20),
       child: Form(
         key: _formKey,
         child: SingleChildScrollView(
           child: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(widget.proposal == null ? 'New Proposal' : 'Edit Proposal', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                   if (widget.proposal == null)
                    TextButton.icon(
                      onPressed: _showTemplates,
                      icon: const Icon(Icons.copy_all, size: 16),
                      label: Text('Use Template', style: GoogleFonts.poppins()),
                    ),
                 ],
               ),
               const SizedBox(height: 20),
               TextFormField(
                 controller: _clientController,
                 decoration: const InputDecoration(labelText: 'Client Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                 validator: (v) => v!.isEmpty ? 'Required' : null,
               ),
               const SizedBox(height: 12),
               TextFormField(
                 controller: _titleController,
                 decoration: const InputDecoration(labelText: 'Project Title', border: OutlineInputBorder(), prefixIcon: Icon(Icons.work)),
                 validator: (v) => v!.isEmpty ? 'Required' : null,
               ),
               const SizedBox(height: 12),
               TextFormField(
                 controller: _budgetController,
                 keyboardType: TextInputType.number,
                 decoration: const InputDecoration(labelText: 'Estimated Budget (\$)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
               ),
               const SizedBox(height: 12),
               Row(
                 children: [
                   Expanded(
                     child: DropdownButtonFormField<String>(
                       value: _status,
                       decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), prefixIcon: Icon(Icons.flag)),
                       items: ['Pending', 'Accepted', 'Rejected'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                       onChanged: (v) => setState(() => _status = v!),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: DropdownButtonFormField<String>(
                       value: _style,
                       decoration: const InputDecoration(labelText: 'PDF Style', border: OutlineInputBorder(), prefixIcon: Icon(Icons.style)),
                       items: ['Creative', 'Corporate', 'Minimal'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                       onChanged: (v) => setState(() => _style = v!),
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 12),
               TextFormField(
                 controller: _descController,
                 maxLines: 4,
                 decoration: const InputDecoration(
                   labelText: 'Description / Scope', 
                   border: OutlineInputBorder(),
                   alignLabelWithHint: true,
                 ),
               ),
               const SizedBox(height: 12),
               TextFormField(
                 controller: _timelineController,
                 maxLines: 4,
                 decoration: const InputDecoration(
                   labelText: 'Timeline & Deliverables (e.g. Phase 1: ...)', 
                   border: OutlineInputBorder(),
                   alignLabelWithHint: true,
                 ),
               ),
               const SizedBox(height: 24),
               Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                   if (widget.proposal != null)
                     TextButton(
                       onPressed: _delete,
                       child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
                     ),
                   const Spacer(),
                   TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins())),
                   const SizedBox(width: 8),
                   ElevatedButton(
                     onPressed: _save, 
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF2196F3),
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                     ),
                     child: Text('Save', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                   ),
                 ],
               ),
             ],
           ),
         ),
       ),
     );
  }
}
