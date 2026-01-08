import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/currency_service.dart';
import '../widgets/app_card.dart';
import 'focus_screen.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Workspace', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Project>('projects').listenable(),
        builder: (context, Box<Project> projectBox, _) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<TaskItem>('tasks').listenable(),
            builder: (context, Box<TaskItem> taskBox, _) {
              return ValueListenableBuilder(
                valueListenable: Hive.box<Invoice>('invoices').listenable(),
                builder: (context, Box<Invoice> invoiceBox, _) {
                  if (projectBox.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_outlined, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No active projects', style: GoogleFonts.poppins(color: Colors.grey[500])),
                        ],
                      ),
                    );
                  }
                  final projects = projectBox.values.toList().cast<Project>();
                  projects.sort((a, b) => a.deadline.compareTo(b.deadline));
                  final tasks = taskBox.values.toList().cast<TaskItem>();
                  final invoices = invoiceBox.values.toList().cast<Invoice>();

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      
                      final projectTasks = tasks.where((t) => t.projectId == project.id).toList();
                      final totalTasks = projectTasks.length;
                      final completedTasks = projectTasks.where((t) => t.isCompleted).length;
                      final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

                      // Calculate Realized Earnings
                      final projectInvoices = invoices.where((i) => i.projectId == project.id && i.status == 'Paid').toList();
                      final realizedEarnings = projectInvoices.fold(0.0, (sum, i) => sum + i.amount);
                      
                      final isOverdue = project.deadline.isBefore(DateTime.now()) && project.status != 'Completed';

                      return AppCard(
                        padding: EdgeInsets.zero,
                        onTap: () => _showAddEditDialog(context, project: project),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20),
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
                                              project.name, 
                                              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)
                                            ),
                                            Text(
                                              project.clientName,
                                              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _statusBadge(context, project.status),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                            color: _getStatusColor(project.status),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${(progress * 100).toInt()}%',
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: _getStatusColor(project.status)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_month_outlined, size: 14, color: isOverdue ? Colors.red : Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat.yMMMd().format(project.deadline),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: isOverdue ? Colors.red : Colors.grey, 
                                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal
                                        ),
                                      ),
                                      const Spacer(),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${CurrencyService.format(realizedEarnings, project.currency)} / ${CurrencyService.format(project.budget, project.currency)}',
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          Text(
                                            'EARNED',
                                            style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // --- Magic Actions Row (Footer) ---
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      // Find the first non-completed task or create one
                                      final taskToStart = projectTasks.where((t) => !t.isCompleted).firstOrNull;
                                      if (taskToStart != null) {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => FocusScreen(task: taskToStart)));
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active tasks found for this project.')));
                                      }
                                    },
                                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                    label: Text('Start Working', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => _generateInvoice(context, project),
                                    icon: const Icon(Icons.receipt_long_outlined, size: 16),
                                    label: Text('Invoice', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                                    style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
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

  void _generateInvoice(BuildContext context, Project project) {
    final invoiceBox = Hive.box<Invoice>('invoices');
    final newInvoiceId = const Uuid().v4();
    
    final newInvoice = Invoice(
      id: newInvoiceId,
      clientName: project.clientName,
      amount: project.budget, 
      date: DateTime.now(),
      status: 'Pending',
      projectId: project.id,
      isExternal: false,
      currency: project.currency,
    );

    invoiceBox.put(newInvoiceId, newInvoice);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invoice generated for ${CurrencyService.format(project.budget, project.currency)}', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Progress': return Colors.blue;
      case 'Completed': return Colors.green;
      case 'On Hold': return Colors.orange;
      case 'Not Started': return Colors.grey;
      default: return Colors.blue;
    }
  }

  void _showAddEditDialog(BuildContext context, {Project? project}) {
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
       child: ProjectForm(project: project),
      ),
    );
  }
}

class ProjectForm extends StatefulWidget {
  final Project? project;

  const ProjectForm({super.key, this.project});

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _budgetController;
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  String _status = 'Not Started';
  
  String? _selectedClientId;
  String _selectedCurrency = 'USD';
  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _budgetController = TextEditingController(text: widget.project?.budget.toString() ?? '');
    _deadline = widget.project?.deadline ?? DateTime.now().add(const Duration(days: 7));
    _status = widget.project?.status ?? 'Not Started';
    if (!['Not Started', 'In Progress', 'On Hold', 'Completed'].contains(_status)) {
       if (_status == 'Active') _status = 'In Progress';
       else _status = 'Not Started';
    }

    _loadClients();
    _initializeFormValues();
  }

  void _loadClients() {
    if (Hive.isBoxOpen('clients')) {
      _clients = Hive.box<Client>('clients').values.toList();
    }
  }

  void _initializeFormValues() {
    if (widget.project != null) {
      _selectedClientId = widget.project?.clientId;
      _selectedCurrency = widget.project?.currency ?? 'USD';

      if (_selectedClientId == null && widget.project!.clientName.isNotEmpty) {
        final match = _clients.firstWhere(
          (c) => c.name.toLowerCase() == widget.project!.clientName.toLowerCase(),
          orElse: () => Client(id: '', name: '', company: '', email: '', phone: '', notes: ''),
        );
        if (match.id.isNotEmpty) {
          _selectedClientId = match.id;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_selectedClientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a client')),
        );
        return;
      }

      final box = Hive.box<Project>('projects');
      final id = widget.project?.id ?? const Uuid().v4();
      
      final client = _clients.firstWhere((c) => c.id == _selectedClientId);

      final newProject = Project(
        id: id,
        name: _nameController.text,
        clientName: client.name,
        clientId: client.id,
        budget: double.tryParse(_budgetController.text) ?? 0.0,
        deadline: _deadline,
        status: _status,
        currency: _selectedCurrency,
      );

      box.put(id, newProject);
      Navigator.pop(context);
    }
  }

  void _delete() {
    if (widget.project != null) {
       final box = Hive.box<Project>('projects');
       box.delete(widget.project!.id);
       Navigator.pop(context);
    }
  }
  
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, 
      initialDate: _deadline, 
      firstDate: DateTime.now().subtract(const Duration(days: 365)), 
      lastDate: DateTime.now().add(const Duration(days: 365 * 5))
    );
    if(picked != null) {
      setState(() => _deadline = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
     final bool hasClients = _clients.isNotEmpty;

     return Padding(
       padding: const EdgeInsets.all(20),
       child: Form(
         key: _formKey,
         child: SingleChildScrollView(
           child: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(widget.project == null ? 'New Project' : 'Edit Project', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
               const SizedBox(height: 20),
               
               if (!hasClients)
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: Colors.amber.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: Colors.amber),
                   ),
                   child: Column(
                     children: [
                       Text('No Clients Found', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                       const SizedBox(height: 4),
                       Text('You must create a client before adding a project.', style: GoogleFonts.poppins(fontSize: 12), textAlign: TextAlign.center),
                       TextButton(
                         onPressed: () {
                           Navigator.pop(context);
                         },
                         child: const Text('Go back to create Client'),
                       )
                     ],
                   ),
                 )
               else
                 DropdownButtonFormField<String>(
                   value: _selectedClientId,
                   items: _clients.map((c) => DropdownMenuItem(
                     value: c.id,
                     child: Text(c.name, overflow: TextOverflow.ellipsis),
                   )).toList(),
                   onChanged: (v) => setState(() => _selectedClientId = v),
                   decoration: const InputDecoration(labelText: 'Select Client', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                   validator: (v) => v == null ? 'Required' : null,
                 ),

               const SizedBox(height: 12),
               
               TextFormField(
                 controller: _nameController,
                 decoration: const InputDecoration(labelText: 'Project Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.folder)),
                 validator: (v) => v!.isEmpty ? 'Required' : null,
               ),
               const SizedBox(height: 12),
               
               Row(
                 children: [
                   Expanded(
                     flex: 2,
                     child: TextFormField(
                       controller: _budgetController,
                       keyboardType: TextInputType.number,
                       decoration: const InputDecoration(labelText: 'Budget', border: OutlineInputBorder(), prefixIcon: Icon(Icons.monetization_on)),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     flex: 1,
                     child: DropdownButtonFormField<String>(
                       value: _selectedCurrency,
                       items: ['USD', 'INR'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                       onChanged: (v) => setState(() => _selectedCurrency = v!),
                       decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()),
                     ),
                   ),
                 ],
               ),

               const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                       value: _status,
                       decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), prefixIcon: Icon(Icons.flag)),
                       items: ['Not Started', 'In Progress', 'On Hold', 'Completed'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                       onChanged: (v) => setState(() => _status = v!),
                     ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Deadline', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today)
                    ),
                    child: Text(DateFormat.yMMMd().format(_deadline), style: GoogleFonts.poppins()),
                  ),
                ),
               const SizedBox(height: 24),
               Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                   if (widget.project != null)
                     TextButton(
                       onPressed: _delete,
                       child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
                     ),
                   const Spacer(),
                   TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins())),
                   const SizedBox(width: 8),
                   ElevatedButton(
                     onPressed: hasClients ? _save : null, 
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
