import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'currency_service.dart';

class InvoicePdfGenerator {
  static Future<pw.Document> generate(Invoice invoice) async {
    final pdf = pw.Document();
    
    // Load branding assets
    final ByteData logoData = await rootBundle.load('assets/images/logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final pw.MemoryImage logo = pw.MemoryImage(logoBytes);

    // Load fonts
    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();

    final accentColor = PdfColor.fromHex('#6366F1'); // Indigo accent

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- Header ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        height: 60,
                        width: 60,
                        child: pw.Image(logo),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text('COMMAND CENTER', style: pw.TextStyle(font: boldFont, fontSize: 12, color: accentColor, letterSpacing: 2)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE', style: pw.TextStyle(font: boldFont, fontSize: 32, color: PdfColors.black)),
                      pw.Text('#${invoice.id.substring(0, 8).toUpperCase()}', style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700)),
                      pw.SizedBox(height: 5),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: invoice.status == 'Paid' ? PdfColors.green100 : PdfColors.orange100,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          invoice.status.toUpperCase(),
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 10,
                            color: invoice.status == 'Paid' ? PdfColors.green : PdfColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 60),

              // --- Billing Info ---
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILL TO', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey700, letterSpacing: 1)),
                        pw.SizedBox(height: 8),
                        pw.Text(invoice.clientName, style: pw.TextStyle(font: boldFont, fontSize: 16)),
                        // We could add client address/email here if available in model
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('ISSUED ON', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey700, letterSpacing: 1)),
                        pw.SizedBox(height: 4),
                        pw.Text(DateFormat('MMMM dd, yyyy').format(invoice.date), style: pw.TextStyle(font: font, fontSize: 12)),
                        pw.SizedBox(height: 15),
                        pw.Text('DUE DATE', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey700, letterSpacing: 1)),
                        pw.SizedBox(height: 4),
                        pw.Text(DateFormat('MMMM dd, yyyy').format(invoice.date.add(const Duration(days: 30))), style: pw.TextStyle(font: font, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 50),

              // --- Items Table ---
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F9FAFB'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('DESCRIPTION', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey700)),
                        pw.Text('AMOUNT', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Professional Freelance Services', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                            pw.Text(invoice.isExternal ? 'General Consulting' : 'Project: ${invoice.projectId ?? "Miscellaneous"}', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
                          ],
                        ),
                        pw.Text(CurrencyService.format(invoice.amount, invoice.currency), style: pw.TextStyle(font: boldFont, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // --- Total & Summary ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('Subtotal', style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700)),
                          pw.SizedBox(width: 40),
                          pw.Text(CurrencyService.format(invoice.amount, invoice.currency), style: pw.TextStyle(font: font, fontSize: 12)),
                        ],
                      ),
                      if (invoice.isGstEnabled) ...[
                        pw.SizedBox(height: 5),
                        pw.Row(
                          children: [
                            pw.Text('GST (${invoice.gstPercentage.toStringAsFixed(0)}%)', style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700)),
                            pw.SizedBox(width: 40),
                            pw.Text(CurrencyService.format(invoice.amount * (invoice.gstPercentage / 100), invoice.currency), style: pw.TextStyle(font: font, fontSize: 12)),
                          ],
                        ),
                      ],
                      pw.SizedBox(height: 10),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        decoration: pw.BoxDecoration(
                          color: accentColor,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Text('TOTAL DUE', style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.white)),
                            pw.SizedBox(width: 40),
                            pw.Text(
                              CurrencyService.format(
                                invoice.isGstEnabled 
                                  ? invoice.amount * (1 + invoice.gstPercentage / 100) 
                                  : invoice.amount, 
                                invoice.currency
                              ), 
                              style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.white)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // --- Footer ---
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by Freelancer Command Center', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500)),
                  pw.Text('Thank you for your business!', style: pw.TextStyle(font: boldFont, fontSize: 10, color: accentColor)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
