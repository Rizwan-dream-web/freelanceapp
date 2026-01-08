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

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Invoices', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Colors.white,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor ?? Colors.black,
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
              return Card(
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () => _showOptionsDialog(context, invoice),
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        invoice.clientName,
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                                      ),
                                      if (invoice.isExternal)
                                        Text('External Invoice', style: GoogleFonts.poppins(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold))
                                      else if (invoice.projectId != null)
                                        Text('Project-based', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                 Text(
                                   CurrencyService.format(invoice.amount, invoice.currency),
                                   style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                                 ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat.yMMMd().format(invoice.date),
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                ),
                                const Spacer(),
                                if (isOverdue)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.red[200]!)
                                    ),
                                    child: Text('OVERDUE (30+)', style: GoogleFonts.poppins(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isPaid)
                        Positioned(
                          right: -10,
                          top: 15,
                          child: Transform.rotate(
                            angle: 0.5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.9),
                                boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)]
                              ),
                              child: Text(
                                'PAID',
                                style: GoogleFonts.courierPrime(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
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
    );
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
                invoice.status = 'Paid';
                invoice.save();
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
    final pdf = await _generatePdfDocument(invoice);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${invoice.clientName}_${DateFormat('yyyyMMdd').format(invoice.date)}',
    );
  }

  Future<void> _sharePdf(BuildContext context, Invoice invoice) async {
     final pdf = await _generatePdfDocument(invoice);
     await Printing.sharePdf(bytes: await pdf.save(), filename: 'Invoice.pdf');
  }

  Future<pw.Document> _generatePdfDocument(Invoice invoice) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
              final currencySymbol = CurrencyService.symbol;
              final displayAmount = CurrencyService.convert(invoice.amount, invoice.currency).toStringAsFixed(2);
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('INVOICE', style: pw.TextStyle(font: boldFont, fontSize: 40)),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Bill To:', style: pw.TextStyle(font: boldFont)),
                          pw.Text(invoice.clientName, style: pw.TextStyle(font: font, fontSize: 18)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Date: ${DateFormat.yMMMd().format(invoice.date)}', style: pw.TextStyle(font: font)),
                          pw.Text('Invoice ID: #${invoice.id.substring(0, 8)}', style: pw.TextStyle(font: font)),
                          pw.SizedBox(height: 10),
                          if(invoice.status == 'Paid')
                             pw.Text('PAID', style: pw.TextStyle(font: boldFont, color: PdfColors.green, fontSize: 20)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 40),
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 1))
                    ),
                    padding: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Description', style: pw.TextStyle(font: boldFont)),
                        pw.Text('Amount', style: pw.TextStyle(font: boldFont)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Freelance Services', style: pw.TextStyle(font: font)),
                      pw.Text('$currencySymbol$displayAmount', style: pw.TextStyle(font: font)),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total', style: pw.TextStyle(font: boldFont, fontSize: 20)),
                      pw.Text('$currencySymbol$displayAmount', style: pw.TextStyle(font: boldFont, fontSize: 20)),
                    ],
                  ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Thank you for your business!', style: pw.TextStyle(font: font, color: PdfColors.grey))),
            ],
          );
        },
      ),
    );
    return pdf;
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
  DateTime _date = DateTime.now();
  String? _selectedProjectId;
  String _currency = 'USD';
  bool _isExternal = false;
  List<Project> _projects = [];

  @override
  void initState() {
    super.initState();
    _clientController = TextEditingController();
    _amountController = TextEditingController();
    _loadProjects();
  }

  void _loadProjects() {
    _projects = Hive.box<Project>('projects').values.toList();
  }

  @override
  void dispose() {
    _clientController.dispose();
    _amountController.dispose();
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
