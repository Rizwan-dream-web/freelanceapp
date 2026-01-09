import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';
import '../services/currency_service.dart';
import '../widgets/app_card.dart';

import 'package:confetti/confetti.dart';
import '../services/invoice_pdf_generator.dart';
import '../services/haptic_service.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('Invoices', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          body: ValueListenableBuilder(
            valueListenable: Hive.box<Invoice>('invoices').listenable(),
            builder: (context, Box<Invoice> box, _) {
              if (box.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No invoices yet', style: GoogleFonts.poppins(color: Colors.grey[500])),
                    ],
                  ),
                );
              }
              final invoices = box.values.toList().cast<Invoice>();
              // Sort by date descending
              invoices.sort((a,b) => b.date.compareTo(a.date));

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: invoices.length,
                itemBuilder: (context, index) {
                  final invoice = invoices[index];
                  final isPaid = invoice.status == 'Paid';
                  final isOverdue = !isPaid && DateTime.now().difference(invoice.date).inDays > 30;

                  return AppCard(
                    padding: EdgeInsets.zero,
                    onTap: () => _showOptionsDialog(context, invoice),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (isPaid ? Colors.green : (isOverdue ? Colors.red : Colors.orange)).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPaid ? Icons.check_circle_outline : (isOverdue ? Icons.priority_high : Icons.receipt_outlined),
                                  color: isPaid ? Colors.green : (isOverdue ? Colors.red : Colors.orange),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      invoice.clientName,
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      '${DateFormat.yMMMd().format(invoice.date)} • ${invoice.isExternal ? "External" : "Project-based"}',
                                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                                    ),
                                    if (invoice.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        invoice.description,
                                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                               Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (invoice.isGstEnabled) ...[
                                      Text(
                                        'Total: ${CurrencyService.format(invoice.amount * (1 + invoice.gstPercentage / 100), invoice.currency)}',
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        'Sub: ${CurrencyService.format(invoice.amount, invoice.currency)} + ${invoice.gstPercentage}% GST',
                                        style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500),
                                      ),
                                    ] else ...[
                                      Text(
                                        CurrencyService.format(invoice.amount, invoice.currency),
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                    if (isOverdue)
                                      Text('OVERDUE', style: GoogleFonts.poppins(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold))
                                    else if (isPaid)
                                      Text('PAID', style: GoogleFonts.poppins(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold))
                                    else
                                      Text('PENDING', style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Row(
                            children: [
                              if (!isPaid)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      invoice.status = 'Paid';
                                      invoice.save();
                                      _confettiController.play();
                                    });
                                  },
                                  icon: const Icon(Icons.done_all, size: 16, color: Colors.green),
                                  label: Text('Mark Paid', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green)),
                                ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.print_outlined, size: 18, color: Colors.grey),
                                onPressed: () => _generateAndPrintPdf(context, invoice),
                                tooltip: 'Print',
                              ),
                              IconButton(
                                icon: const Icon(Icons.share_outlined, size: 18, color: Colors.grey),
                                onPressed: () => _sharePdf(context, invoice),
                                tooltip: 'Share',
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
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddDialog(context),
            backgroundColor: const Color(0xFF2196F3),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
        
        // --- Confetti Overlay ---
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            createParticlePath: _drawStar,
          ),
        ),
      ],
    );
  }

  Path _drawStar(Size size) {
    // Basic star shape
    double degToRad(double deg) => deg * (3.1415926535897932 / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(-90);
    path.moveTo(size.width, halfWidth + externalRadius * 0); // Simplified
    for (double step = 0; step < 360; step += 360 / numberOfPoints) {
       path.lineTo(halfWidth + externalRadius * 0, halfWidth); // Placeholder for real star logic
    }
    // Let's just use a simple circle/diamond if star is too complex for shorthand
    return Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  void _showAddDialog(BuildContext context) {
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
       child: const InvoiceForm(),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, Invoice invoice) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text('Mark as Paid', style: GoogleFonts.poppins()),
              onTap: () {
                setState(() {
                  invoice.status = 'Paid';
                  invoice.save();
                  _confettiController.play();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text('View/Print PDF', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _generateAndPrintPdf(context, invoice);
              },
            ),
             ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: Text('Share Invoice', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _sharePdf(context, invoice);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.grey),
              title: Text('Delete', style: GoogleFonts.poppins()),
              onTap: () {
                invoice.delete();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndPrintPdf(BuildContext context, Invoice invoice) async {
    final pdf = await InvoicePdfGenerator.generate(invoice);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${invoice.clientName}_${DateFormat('yyyyMMdd').format(invoice.date)}',
    );
  }

  Future<void> _sharePdf(BuildContext context, Invoice invoice) async {
     final pdf = await InvoicePdfGenerator.generate(invoice);
     await Printing.sharePdf(bytes: await pdf.save(), filename: 'Invoice.pdf');
  }
}

class InvoiceForm extends StatefulWidget {
  const InvoiceForm({super.key});

  @override
  State<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clientController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  DateTime _date = DateTime.now();
  String? _selectedProjectId;
  String _currency = 'USD';
  bool _isExternal = false;
  bool _isGstEnabled = false;
  double _gstPercentage = 18.0;
  List<Project> _projects = [];

  @override
  void initState() {
    super.initState();
    _clientController = TextEditingController();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadProjects();
  }

  void _loadProjects() {
    _projects = Hive.box<Project>('projects').values.toList();
  }

  @override
  void dispose() {
    _clientController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<Invoice>('invoices');
      final id = const Uuid().v4();
      final newInvoice = Invoice(
        id: id,
        clientName: _clientController.text,
        amount: double.parse(_amountController.text),
        date: _date,
        currency: _currency,
        isExternal: _isExternal,
        projectId: _isExternal ? null : _selectedProjectId,
        isGstEnabled: _isGstEnabled,
        gstPercentage: _gstPercentage,
        description: _descriptionController.text,
      );

      box.put(id, newInvoice);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
      double hourlyRate = Hive.box('settings').get('defaultRate', defaultValue: 50.0);
      double taxRate = Hive.box('settings').get('defaultTax', defaultValue: 0.0);
      
      // Initialize if empty (and not edited by user manually yet - simple check)
      if (_amountController.text.isEmpty) {
         // Maybe don't auto-fill amount immediately to avoid confusion, 
         // but we can offer a "Calculate" button or fields.
      }

      return Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Invoice', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                // --- External Toggle ---
                SwitchListTile(
                  title: Text('External Invoice', style: GoogleFonts.poppins(fontSize: 14)),
                  subtitle: Text('Not linked to any project', style: GoogleFonts.poppins(fontSize: 10)),
                  value: _isExternal, 
                  onChanged: (v) => setState(() => _isExternal = v),
                ),
                const SizedBox(height: 12),

                if (!_isExternal) ...[
                   DropdownButtonFormField<String>(
                     value: _selectedProjectId,
                     decoration: const InputDecoration(labelText: 'Linked Project', border: OutlineInputBorder(), prefixIcon: Icon(Icons.work_outline)),
                     items: _projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                     onChanged: (v) {
                       setState(() {
                         _selectedProjectId = v;
                         final p = _projects.firstWhere((proj) => proj.id == v);
                         _clientController.text = p.clientName;
                         _currency = p.currency;
                       });
                     },
                     validator: (v) => !_isExternal && v == null ? 'Required' : null,
                   ),
                   const SizedBox(height: 12),
                ],

                TextFormField(
                  controller: _clientController,
                  decoration: const InputDecoration(labelText: 'Client Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _currency,
                        decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()),
                        items: ['USD', 'INR'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _currency = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Total Amount', 
                          border: const OutlineInputBorder(), 
                          prefixText: _currency == 'INR' ? '₹' : '\$',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // --- GST Support ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isGstEnabled ? Colors.green.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Enable GST (India)', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text('Adds GST breakdown to invoice', style: GoogleFonts.poppins(fontSize: 10)),
                        value: _isGstEnabled, 
                        onChanged: (v) => setState(() => _isGstEnabled = v),
                      ),
                      if (_isGstEnabled) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('GST Rate', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Container(
                              width: 80,
                              child: TextFormField(
                                initialValue: _gstPercentage.toStringAsFixed(0),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(suffixText: '%', isDense: true),
                                onChanged: (v) => setState(() => _gstPercentage = double.tryParse(v) ?? 18.0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description / Notes',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Smart Calculator ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                       Text('Smart Calculator', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 10),
                       Row(
                         children: [
                           Expanded(
                             child: TextFormField(
                               keyboardType: TextInputType.number,
                               decoration: const InputDecoration(labelText: 'Hours', isDense: true, border: OutlineInputBorder()),
                               onChanged: (val) {
                                 final h = double.tryParse(val) ?? 0;
                                 final calculated = h * hourlyRate;
                                 final withTax = calculated * (1 + taxRate/100);
                                 setState(() {
                                    _amountController.text = withTax.toStringAsFixed(2);
                                 });
                               },
                             ),
                           ),
                           const SizedBox(width: 10),
                           Expanded(
                             child: TextFormField(
                               initialValue: hourlyRate.toString(),
                               keyboardType: TextInputType.number,
                               decoration: const InputDecoration(labelText: 'Rate/hr', isDense: true, border: OutlineInputBorder()),
                               onChanged: (val) => hourlyRate = double.tryParse(val) ?? 0,
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 8),
                       Text('Includes $taxRate% Tax (Change in Settings)', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                 InkWell(
                   onTap: () async {
                     final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                     if(picked != null) setState(() => _date = picked);
                   },
                   child: InputDecorator(
                     decoration: const InputDecoration(
                       labelText: 'Date', 
                       border: OutlineInputBorder(),
                       prefixIcon: Icon(Icons.calendar_today)
                     ),
                     child: Text(DateFormat.yMMMd().format(_date), style: GoogleFonts.poppins()),
                   ),
                 ),
                 const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins())),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _save, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text('Create', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
