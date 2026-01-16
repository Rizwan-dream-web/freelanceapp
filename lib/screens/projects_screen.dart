import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/currency_service.dart';
import '../widgets/app_card.dart';
import '../services/haptic_service.dart';
import 'focus_screen.dart';
import '../widgets/animations.dart';
import '../widgets/loading.dart';
import '../utils/validators.dart';
import '../utils/error_handler.dart';
import '../widgets/forms.dart';
import 'package:go_router/go_router.dart';
import '../repositories/repository_manager.dart';
import '../services/notification_service.dart';

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
      body: StreamBuilder<List<Project>>(
        stream: repositoryManager.projects.getAll(),
        initialData: repositoryManager.projects.getAllSync(),
        builder: (context, projectSnapshot) {
          return StreamBuilder<List<TaskItem>>(
            stream: repositoryManager.tasks.getAll(),
            initialData: repositoryManager.tasks.getAllSync(),
            builder: (context, taskSnapshot) {
              return StreamBuilder<List<Invoice>>(
                stream: repositoryManager.invoices.getAll(),
                initialData: repositoryManager.invoices.getAllSync(),
                builder: (context, invoiceSnapshot) {
                  // Only show loading if we genuinely have no data (which shouldn't happen with initialData)
                  if (!projectSnapshot.hasData || !taskSnapshot.hasData || !invoiceSnapshot.hasData) {
                    return const LoadingOverlay(isLoading: true, child: SizedBox.shrink());
                  }

                  final projects = projectSnapshot.data!;
                  projects.sort((a, b) => a.deadline.compareTo(b.deadline));
                  final tasks = taskSnapshot.data!;
                  final invoices = invoiceSnapshot.data!;

                  if (projects.isEmpty) {
                    return LoadingOverlay(
                      isLoading: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: 1.0,
                              duration: AppAnimations.normal,
                              child: Icon(Icons.folder_open_outlined, size: 60, color: Colors.grey[300]),
                            ),
                            const SizedBox(height: 16),
                            AnimatedSlide(
                              offset: Offset.zero,
                              duration: AppAnimations.normal,
                              curve: AppAnimations.easeOut,
                              child: Text('No active projects', style: GoogleFonts.poppins(color: Colors.grey[500])),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return LoadingOverlay(
                    isLoading: false,
                    child: ListView.builder(
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

                        return AnimatedSlide(
                          offset: Offset(0, 0.1 + (index * 0.05)),
                          duration: Duration(milliseconds: 400 + (index * 100)),
                          curve: AppAnimations.easeOut,
                          child: AnimatedOpacity(
                            opacity: 1.0,
                            duration: Duration(milliseconds: 500 + (index * 100)),
                            child: AppCard(
                              padding: EdgeInsets.zero,
                              margin: const EdgeInsets.only(bottom: 20),
                              onTap: () {
                                HapticService.light();
                                context.push('/project-detail', extra: project);
                              },
                              onLongPress: () => _showAddEditDialog(context, project: project),
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
                                                  AnimatedSlide(
                                                    offset: Offset.zero,
                                                    duration: AppAnimations.normal,
                                                    child: Text(
                                                      project.name, 
                                                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)
                                                    ),
                                                  ),
                                                  AnimatedOpacity(
                                                    opacity: 1.0,
                                                    duration: AppAnimations.normal,
                                                    child: Text(
                                                      project.clientName,
                                                      style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                                                    ),
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
                                              child: TweenAnimationBuilder<double>(
                                                tween: Tween<double>(begin: 0, end: progress),
                                                duration: const Duration(milliseconds: 1200),
                                                curve: Curves.easeOutExpo,
                                                builder: (context, val, _) {
                                                  return ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: LinearProgressIndicator(
                                                      value: val,
                                                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                                      color: _getStatusColor(project.status),
                                                      minHeight: 6,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '${(progress * 100).toInt()}% Done',
                                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: _getStatusColor(project.status)),
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
                                            _buildProjectHealth(context, progress, realizedEarnings, project.budget),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // --- Magic Actions Row (Footer) ---
                                  AnimatedContainer(
                                    duration: AppAnimations.normal,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    child: Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () {
                                            final taskToStart = projectTasks.where((t) => !t.isCompleted).firstOrNull;
                                            if (taskToStart != null) {
                                              Navigator.push(context, MaterialPageRoute(builder: (_) => FocusScreen(task: taskToStart)));
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active tasks found for this project.')));
                                            }
                                          },
                                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                          label: Text('START WORK', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
                                        ),
                                        const Spacer(),
                                        if (realizedEarnings < project.budget)
                                          TextButton.icon(
                                            onPressed: () => _generateInvoice(context, project),
                                            icon: const Icon(Icons.receipt_long_outlined, size: 16),
                                            label: Text('INVOICE', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: AnimatedScale(
        scale: 1.0,
        duration: AppAnimations.normal,
        child: FloatingActionButton(
          onPressed: () => _showAddEditDialog(context),
          backgroundColor: const Color(0xFF2196F3),
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

  Widget _buildProjectHealth(BuildContext context, double workProgress, double earned, double totalBudget) {
    final budgetProgress = totalBudget == 0 ? 0.0 : earned / totalBudget;
    
    // Health is good if budget realization is ahead of or equal to work progress
    // If workProgress is high but budgetProgress is low, health is "At Risk" (Uninvoiced work)
    final healthRatio = workProgress == 0 ? 1.0 : (budgetProgress / workProgress);
    
    Color healthColor = Colors.green;
    String healthLabel = "HEALTHY";
    
    if (healthRatio < 0.5) {
      healthColor = Colors.red;
      healthLabel = "AT RISK";
    } else if (healthRatio < 0.9) {
      healthColor = Colors.orange;
      healthLabel = "BEHIND";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             Container(
               width: 8, height: 8,
               decoration: BoxDecoration(color: healthColor, shape: BoxShape.circle),
             ),
             const SizedBox(width: 6),
             Text(healthLabel, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: healthColor, letterSpacing: 1)),
           ],
        ),
        const SizedBox(height: 2),
        Text(
          '${(budgetProgress * 100).toInt()}% Revenue',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  void _generateInvoice(BuildContext context, Project project) async {
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

    await repositoryManager.invoices.save(newInvoice);

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

class _ProjectFormState extends State<ProjectForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _budgetController;
  late TextEditingController _hoursController;
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  String _status = 'Not Started';
  
  String? _selectedClientId;
  String _selectedCurrency = 'USD';
  List<Client> _clients = [];

  // Animation and validation state
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  String? _nameError;
  String? _budgetError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _budgetController = TextEditingController(text: widget.project?.budget.toString() ?? '');
    _hoursController = TextEditingController(text: widget.project?.estimatedHours.toString() ?? '');
    _deadline = widget.project?.deadline ?? DateTime.now().add(const Duration(days: 7));
    _status = widget.project?.status ?? 'Not Started';
    if (!['Not Started', 'In Progress', 'On Hold', 'Completed'].contains(_status)) {
       if (_status == 'Active') _status = 'In Progress';
       else _status = 'Not Started';
    }

    // Initialize animations
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _loadClients();
    _initializeFormValues();

    // Add validation listeners
    _nameController.addListener(_validateName);
    _budgetController.addListener(_validateBudget);
  }

  void _loadClients() async {
    _clients = await repositoryManager.clients.getAllOnce();
    if (mounted) setState(() {});
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
    _hoursController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _validateName() {
    setState(() {
      _nameError = Validators.validateRequired(_nameController.text, 'Project name');
    });
  }

  void _validateBudget() {
    setState(() {
      _budgetError = Validators.validateBudget(_budgetController.text);
    });
  }

  void _save() async {
    // Validate all fields
    _validateName();
    _validateBudget();

    if (_selectedClientId == null) {
      context.showAnimatedErrorSnackBar('Please select a client');
      _shakeController.forward(from: 0);
      return;
    }

    if (_nameError != null || _budgetError != null) {
      context.showAnimatedErrorSnackBar('Please fix the errors above');
      _shakeController.forward(from: 0);
      return;
    }

    setState(() => _isSaving = true);

    try {
      HapticService.success();
      final id = widget.project?.id ?? const Uuid().v4();

      final client = _clients.firstWhere((c) => c.id == _selectedClientId);

      final newProject = Project(
        id: id,
        name: _nameController.text.trim(),
        clientName: client.name,
        clientId: client.id,
        budget: double.tryParse(_budgetController.text) ?? 0.0,
        deadline: _deadline,
        status: _status,
        currency: _selectedCurrency,
        estimatedHours: int.tryParse(_hoursController.text) ?? 0,
      );

      await repositoryManager.projects.save(newProject);
      await NotificationService.scheduleProjectReminders(newProject);

      if (mounted) {
        Navigator.pop(context);
        context.showAnimatedSuccess(
          'Project Saved',
          'Project has been saved successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showAnimatedError(
          'Save Failed',
          'Unable to save project information.',
          details: e.toString(),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _save();
              },
              child: const Text('Retry'),
            ),
          ],
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _delete() async {
    if (widget.project == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Project', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete "${widget.project!.name}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      HapticService.medium();
      await repositoryManager.projects.delete(widget.project!.id);

      if (mounted) {
        Navigator.pop(context);
        context.showAnimatedSuccess(
          'Project Deleted',
          'Project has been removed from your workspace.',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showAnimatedError(
          'Delete Failed',
          'Unable to delete project information.',
          details: e.toString(),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _delete();
              },
              child: const Text('Retry'),
            ),
          ],
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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

     return AnimatedBuilder(
       animation: _shakeAnimation,
       builder: (context, child) {
         return Transform.translate(
           offset: Offset(_shakeAnimation.value, 0),
           child: Padding(
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
                     
                     AnimatedTextField(
                       controller: _nameController,
                       labelText: 'Project Name',
                       prefixIcon: const Icon(Icons.folder),
                       errorText: _nameError,
                       validator: (value) => Validators.validateRequired(value, 'Project name'),
                     ),
                     const SizedBox(height: 12),
                     
                     Row(
                       children: [
                         Expanded(
                           flex: 2,
                           child: AnimatedTextField(
                             controller: _budgetController,
                             labelText: 'Budget',
                             prefixIcon: const Icon(Icons.monetization_on),
                             keyboardType: TextInputType.number,
                             errorText: _budgetError,
                             validator: Validators.validateBudget,
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
                            labelText: 'Deadline (Mandatory)', 
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today)
                          ),
                          child: Text(DateFormat.yMMMd().format(_deadline), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedTextField(
                        controller: _hoursController,
                        labelText: 'Estimated Hours (Optional)',
                        prefixIcon: const Icon(Icons.timer_outlined),
                        keyboardType: TextInputType.number,
                      ),
                     const SizedBox(height: 24),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         if (widget.project != null)
                           TextButton(
                             onPressed: _isSaving ? null : _delete,
                             child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
                           ),
                         const Spacer(),
                         TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins())),
                         const SizedBox(width: 8),
                         ElevatedButton(
                           onPressed: hasClients && !_isSaving ? _save : null, 
                           style: ElevatedButton.styleFrom(
                             backgroundColor: const Color(0xFF2196F3),
                             foregroundColor: Colors.white,
                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                           ),
                           child: _isSaving
                             ? const SizedBox(
                                 width: 20,
                                 height: 20,
                                 child: CircularProgressIndicator(strokeWidth: 2),
                               )
                             : Text('Save', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                         ),
                       ],
                     ),
                   ],
                 ),
               ),
             ),
           ),
         );
       },
     );
  }
}
