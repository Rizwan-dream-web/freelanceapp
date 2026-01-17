import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../widgets/app_card.dart';
import '../services/haptic_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../utils/validators.dart';
import '../utils/error_handler.dart';
import '../widgets/animations.dart';
import '../widgets/loading.dart';
import '../widgets/forms.dart';
import '../widgets/buttons.dart';
import '../repositories/repository_manager.dart';
import '../services/currency_service.dart';
import '../widgets/client_history_sheet.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Clients', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: StreamBuilder<List<Client>>(
        stream: repositoryManager.clients.getAll(),
        initialData: repositoryManager.clients.getAllSync(),
        builder: (context, clientSnapshot) {
          return StreamBuilder<List<Invoice>>(
            stream: repositoryManager.invoices.getAll(),
            initialData: repositoryManager.invoices.getAllSync(),
            builder: (context, invoiceSnapshot) {
              // If still no data (shouldn't happen with initialData), show loading
              if (!clientSnapshot.hasData) {
                 return const LoadingOverlay(isLoading: true, child: SizedBox.shrink());
              }
              
              if (clientSnapshot.data!.isEmpty) {
                return LoadingOverlay(
                   isLoading: false,
                   child: _buildEmptyState(context),
                );
              }

              final clients = clientSnapshot.data!;
              final invoices = invoiceSnapshot.data ?? [];

              return LoadingOverlay(
                isLoading: false,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    // Calculate Lifetime Value
                    final clientInvoices = invoices.where((i) => i.clientName.toLowerCase() == client.name.toLowerCase() && i.status == InvoiceStatus.paid);
                    final lifetimeValue = clientInvoices.fold(0.0, (sum, i) => sum + i.amount);

                    // Calculate Health Score
                    final lastInvoiceDate = clientInvoices.isNotEmpty
                        ? clientInvoices.map((i) => i.date).reduce((a, b) => a.isAfter(b) ? a : b)
                        : null;
                    final isRecent = lastInvoiceDate != null && DateTime.now().difference(lastInvoiceDate).inDays < AppDefaults.recentActivityDays;
                    final isHighValue = lifetimeValue > AppDefaults.vipThreshold;

                    Color healthColor = Colors.grey;
                    String healthText = ClientHealth.inactive;
                    if (isHighValue && isRecent) {
                      healthColor = Colors.green;
                      healthText = ClientHealth.vip;
                    } else if (isRecent) {
                      healthColor = Colors.blue;
                      healthText = ClientHealth.active;
                    } else if (lifetimeValue > 0) {
                       healthColor = Colors.orange;
                       healthText = ClientHealth.dormant;
                    }

                    return AnimatedSlide(
                      offset: Offset(0, 0.1 + (index * 0.05)),
                      duration: Duration(milliseconds: 400 + (index * 100)),
                      curve: AppAnimations.easeOut,
                      child: AnimatedOpacity(
                        opacity: 1.0,
                        duration: Duration(milliseconds: 500 + (index * 100)),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: AppCard(
                            padding: EdgeInsets.zero,
                            onTap: () => _showAddEditDialog(context, client: client),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AnimatedScale(
                                        scale: 1.0,
                                        duration: AppAnimations.normal,
                                        child: Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: healthColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: healthColor, fontSize: 24),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AnimatedSlide(
                                              offset: Offset.zero,
                                              duration: AppAnimations.normal,
                                              child: Text(client.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                                            ),
                                            if (client.company.isNotEmpty)
                                              AnimatedOpacity(
                                                opacity: 1.0,
                                                duration: AppAnimations.normal,
                                                child: Text(client.company, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                              ),
                                            const SizedBox(height: 8),
                                            _healthBadge(healthText, healthColor),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text('LIFETIME VALUE', style: GoogleFonts.poppins(fontSize: 8, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                          ),
                                          const SizedBox(height: 4),
                                          TweenAnimationBuilder<double>(
                                            tween: Tween<double>(begin: 0, end: lifetimeValue),
                                            duration: const Duration(milliseconds: 1200),
                                            curve: Curves.easeOutExpo,
                                            builder: (context, val, _) {
                                              return Text(
                                                '${CurrencyService.getSymbol(CurrencyService.globalCurrency)}${NumberFormat('#,###').format(val.toInt())}',
                                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Magic Actions Footer
                                AnimatedContainer(
                                  duration: AppAnimations.normal,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  child: Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _launchEmail(context, client.email),
                                        icon: const Icon(Icons.email_outlined, size: 16),
                                        label: Text('Email', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                                        style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _launchPhone(context, client.phone),
                                        icon: const Icon(Icons.phone_outlined, size: 16),
                                        label: Text('Call', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                                        style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () {
                                          HapticService.medium();
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => ClientHistorySheet(client: client),
                                          );
                                        },
                                        child: Text('View History', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
      ),
      floatingActionButton: AnimatedScale(
        scale: 1.0,
        duration: AppAnimations.normal,
        child: FloatingActionButton(
          onPressed: () => _showAddEditDialog(context),
          backgroundColor: const Color(0xFF2196F3),
          child: Icon(Icons.person_add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _healthBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email provided for this client')),
      );
      return;
    }
    
    try {
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: email,
      );
      // For email, it's often better to just launch and catch the error
      // as canLaunchUrl can be unreliable on newer Android versions without proper intent queries
      final bool launched = await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        throw 'Launch failed';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch email app. Please ensure an email app is installed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _launchPhone(BuildContext context, String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number provided for this client')),
      );
      return;
    }
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(phoneLaunchUri)) {
      await launchUrl(phoneLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone app')),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: 1.0,
            duration: AppAnimations.normal,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline, size: 60, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSlide(
            offset: Offset.zero,
            duration: AppAnimations.normal,
            curve: AppAnimations.easeOut,
            child: Text(
              'No clients added yet',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: 1.0,
            duration: AppAnimations.normal,
            child: Text(
              'Your future network starts here.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 32),
          AnimatedScale(
            scale: 1.0,
            duration: AppAnimations.normal,
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(context),
              icon: const Icon(Icons.add),
              label: Text('Add Your First Client', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {Client? client}) {
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
       child: ClientForm(client: client),
      ),
    );
  }
}

class ClientForm extends StatefulWidget {
  final Client? client;

  const ClientForm({super.key, this.client});

  @override
  State<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<ClientForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;

  bool _isSaving = false;
  bool _isDeleting = false;
  
  // Validation state
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  
  // Animation controllers for validation feedback
  late AnimationController _validationController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.name ?? '');
    _companyController = TextEditingController(text: widget.client?.company ?? '');
    _emailController = TextEditingController(text: widget.client?.email ?? '');
    _phoneController = TextEditingController(text: widget.client?.phone ?? '');
    _notesController = TextEditingController(text: widget.client?.notes ?? '');
    
    // Initialize validation animation
    _validationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _validationController, curve: Curves.elasticIn),
    );
    
    // Add real-time validation listeners
    _nameController.addListener(_validateName);
    _emailController.addListener(_validateEmail);
    _phoneController.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _validationController.dispose();
    super.dispose();
  }

  void _validateName() {
    setState(() {
      _nameError = Validators.required(_nameController.text, fieldName: 'Name');
    });
  }

  void _validateEmail() {
    setState(() {
      _emailError = Validators.email(_emailController.text);
    });
  }

  void _validatePhone() {
    setState(() {
      _phoneError = Validators.phone(_phoneController.text);
    });
  }

  void _triggerValidationAnimation() {
    _validationController.forward(from: 0);
  }

  Future<void> _save() async {
    // Perform final validation
    _validateName();
    _validateEmail();
    _validatePhone();
    
    if (_nameError != null || _emailError != null || _phoneError != null) {
      _triggerValidationAnimation();
      HapticService.error();
      return;
    }

    setState(() => _isSaving = true);

    try {
      HapticService.success();
      final id = widget.client?.id ?? const Uuid().v4();
      final newClient = Client(
        id: id,
        name: _nameController.text.trim(),
        company: _companyController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        notes: _notesController.text.trim(),
      );

      await repositoryManager.clients.save(newClient);

      if (mounted) {
        Navigator.pop(context);
        context.showAnimatedSuccess(
          'Client Saved',
          'Client information has been saved successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showAnimatedError(
          'Save Failed',
          'Unable to save client information.',
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

  Future<void> _delete() async {
    if (widget.client == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Client', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete ${widget.client!.name}? This action cannot be undone.',
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

    setState(() => _isDeleting = true);

    try {
      HapticService.medium();
      await repositoryManager.clients.delete(widget.client!.id);

      if (mounted) {
        Navigator.pop(context);
        context.showAnimatedSuccess(
          'Client Deleted',
          'Client has been removed from your contacts.',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showAnimatedError(
          'Delete Failed',
          'Unable to delete client information.',
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
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    AnimatedSlide(
                      offset: Offset.zero,
                      duration: AppAnimations.normal,
                      curve: AppAnimations.easeOut,
                      child: Text(
                        widget.client == null ? 'New Client' : 'Edit Client', 
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedTextField(
                      controller: _nameController,
                      labelText: 'Full Name *',
                      hintText: 'Enter client full name',
                      errorText: _nameError,
                      prefixIcon: const Icon(Icons.person),
                      onChanged: (_) => _validateName(),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    AnimatedTextField(
                      controller: _companyController,
                      labelText: 'Company / Brand',
                      hintText: 'Enter company or brand name',
                      prefixIcon: const Icon(Icons.business),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    AnimatedTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      hintText: 'client@example.com',
                      errorText: _emailError,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email),
                      onChanged: (_) => _validateEmail(),
                    ),
                    const SizedBox(height: 12),
                    AnimatedTextField(
                      controller: _phoneController,
                      labelText: 'Phone',
                      hintText: '+1 234 567 8900',
                      errorText: _phoneError,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone),
                      onChanged: (_) => _validatePhone(),
                    ),
                    const SizedBox(height: 12),
                    AnimatedTextField(
                      controller: _notesController,
                      labelText: 'Notes',
                      hintText: 'Additional notes about this client',
                      maxLines: 2,
                      prefixIcon: const Icon(Icons.note),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSlide(
                      offset: Offset.zero,
                      duration: AppAnimations.normal,
                      curve: AppAnimations.easeOut,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (widget.client != null)
                            AnimatedButton(
                              onPressed: _isDeleting || _isSaving ? null : _delete,
                              backgroundColor: Colors.red.withOpacity(0.1),
                              foregroundColor: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: _isDeleting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                                    )
                                  : Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            ),
                          const Spacer(),
                          AnimatedButton(
                            onPressed: _isSaving || _isDeleting ? null : () => Navigator.pop(context),
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            foregroundColor: Colors.grey[700]!,
                            borderRadius: BorderRadius.circular(8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          AnimatedButton(
                            onPressed: _isSaving || _isDeleting ? null : _save,
                            backgroundColor: _nameError != null || _emailError != null || _phoneError != null 
                                ? Colors.grey 
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('Save', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
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
