import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../widgets/app_card.dart';
import '../services/haptic_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/skeleton_loader.dart';

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
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Client>('clients').listenable(),
        builder: (context, Box<Client> clientBox, _) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<Invoice>('invoices').listenable(),
            builder: (context, Box<Invoice> invoiceBox, _) {
              if (clientBox.isEmpty) {
                return _buildEmptyState(context);
              }

              final clients = clientBox.values.toList().cast<Client>();
              final invoices = invoiceBox.values.toList().cast<Invoice>();
              
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final client = clients[index];
                  // Calculate Lifetime Value
                  final clientInvoices = invoices.where((i) => i.clientName.toLowerCase() == client.name.toLowerCase() && i.status == 'Paid');
                  final lifetimeValue = clientInvoices.fold(0.0, (sum, i) => sum + i.amount);

                  // Calculate Health Score
                  final lastInvoiceDate = clientInvoices.isNotEmpty 
                      ? clientInvoices.map((i) => i.date).reduce((a, b) => a.isAfter(b) ? a : b)
                      : null;
                  final isRecent = lastInvoiceDate != null && DateTime.now().difference(lastInvoiceDate).inDays < 60;
                  final isHighValue = lifetimeValue > 5000;

                  Color healthColor = Colors.grey;
                  String healthText = 'Inactive';
                  if (isHighValue && isRecent) {
                    healthColor = Colors.green;
                    healthText = 'VIP';
                  } else if (isRecent) {
                    healthColor = Colors.blue;
                    healthText = 'Active';
                  } else if (lifetimeValue > 0) {
                     healthColor = Colors.orange;
                     healthText = 'Dormant';
                  }
                  
                  return AppCard(
                    padding: EdgeInsets.zero,
                    onTap: () => _showAddEditDialog(context, client: client),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
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
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(client.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                                    if (client.company.isNotEmpty)
                                      Text(client.company, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 8),
                                    _healthBadge(healthText, healthColor),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('LTV', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  Text(
                                    '\$${lifetimeValue.toInt()}',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Magic Actions Footer
                        Container(
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
                                onPressed: () {},
                                child: Text('View History', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: Icon(Icons.person_add, color: Theme.of(context).colorScheme.onPrimary),
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline, size: 60, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'No clients added yet',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your future network starts here.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(context),
            icon: const Icon(Icons.add),
            label: Text('Add Your First Client', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

class _ClientFormState extends State<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.name ?? '');
    _companyController = TextEditingController(text: widget.client?.company ?? '');
    _emailController = TextEditingController(text: widget.client?.email ?? '');
    _phoneController = TextEditingController(text: widget.client?.phone ?? '');
    _notesController = TextEditingController(text: widget.client?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      HapticService.success();
      final box = Hive.box<Client>('clients');
      final id = widget.client?.id ?? const Uuid().v4();
      final newClient = Client(
        id: id,
        name: _nameController.text,
        company: _companyController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        notes: _notesController.text,
      );

      box.put(id, newClient);
      Navigator.pop(context);
    }
  }

  void _delete() {
    if (widget.client != null) {
       HapticService.medium();
       final box = Hive.box<Client>('clients');
       box.delete(widget.client!.id);
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
               Text(widget.client == null ? 'New Client' : 'Edit Client', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
               const SizedBox(height: 20),
               TextFormField(
                 controller: _nameController,
                 decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                 validator: (v) => v!.isEmpty ? 'Required' : null,
               ),
               const SizedBox(height: 12),
               TextFormField(
                 controller: _companyController,
                 decoration: const InputDecoration(labelText: 'Company / Brand', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
               ),
               const SizedBox(height: 12),
               TextFormField(
                 controller: _emailController,
                 keyboardType: TextInputType.emailAddress,
                 decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
               ),
               const SizedBox(height: 12),
               TextFormField(
                 controller: _phoneController,
                 keyboardType: TextInputType.phone,
                 decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
               ),
               const SizedBox(height: 12),
               TextFormField(
                 controller: _notesController,
                 maxLines: 2,
                 decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder(), prefixIcon: Icon(Icons.note)),
               ),
               const SizedBox(height: 24),
               Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                   if (widget.client != null)
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
