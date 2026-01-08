import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/currency_service.dart';

class ProposalPdfGenerator {
  static Future<void> generateAndShow(Proposal proposal) async {
    final pdf = pw.Document();

    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.poppinsRegular(),
      bold: await PdfGoogleFonts.poppinsBold(),
      italic: await PdfGoogleFonts.poppinsItalic(), 
    );

    // --- Cover Page ---
    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          theme: theme,
          margin: const pw.EdgeInsets.all(0),
        ),
        build: (context) {
          return pw.Container(
            decoration: const pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [PdfColors.blue900, PdfColors.indigo900],
              ),
            ),
            padding: const pw.EdgeInsets.all(60),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor(1, 1, 1, 0.1),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'BUSINESS PROPOSAL',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  proposal.projectTitle.toUpperCase(),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 48,
                    fontWeight: pw.FontWeight.bold,
                    lineSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(width: 120, height: 6, color: PdfColors.amber400),
                pw.SizedBox(height: 60),
                pw.Text(
                  'PREPARED FOR',
                  style: pw.TextStyle(color: const PdfColor(1, 1, 1, 0.6), fontSize: 10, letterSpacing: 1),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  proposal.clientName,
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DATE ISSUED', style: pw.TextStyle(color: const PdfColor(1, 1, 1, 0.6), fontSize: 9)),
                        pw.Text(DateFormat.yMMMMd().format(proposal.dateSent), style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('PROPOSAL ID', style: pw.TextStyle(color: const PdfColor(1, 1, 1, 0.6), fontSize: 9)),
                        pw.Text(proposal.id.substring(0, 8).toUpperCase(), style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // --- Content Page ---
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          margin: const pw.EdgeInsets.all(50),
        ),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('FREELANCE PRO', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.Text('AGENCY-GRADE SERVICES', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
              pw.Text('PROJECT PROPOSAL', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              pw.Text('Confidential', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            ],
          ),
        ),
        build: (context) => [
          pw.Text('Executive Summary', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.SizedBox(height: 15),
          pw.Text(
            proposal.description,
            style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.6, color: PdfColors.grey800),
          ),
          
          pw.SizedBox(height: 40),
          pw.Text('Timeline & Deliverables', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.SizedBox(height: 15),
          
          if (proposal.timeline.isEmpty)
            pw.Text('Project timeline to be discussed based on requirements.', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600))
          else
            ...proposal.timeline.split('\n').where((l) => l.trim().isNotEmpty).map((line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 4, right: 10),
                    width: 6, height: 6,
                    decoration: const pw.BoxDecoration(color: PdfColors.amber700, shape: pw.BoxShape.circle),
                  ),
                  pw.Expanded(
                    child: pw.Text(line.trim(), style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.4, color: PdfColors.grey800)),
                  ),
                ],
              ),
            )).toList(),

          pw.SizedBox(height: 60),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.indigo50,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColors.indigo100),
            ),
            padding: const pw.EdgeInsets.all(25),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Estimated Investment', style: pw.TextStyle(fontSize: 12, color: PdfColors.indigo700, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Full Project Deliverables', style: pw.TextStyle(fontSize: 9, color: PdfColors.indigo300)),
                      ],
                    ),
                    pw.Text(
                      '${CurrencyService.symbol}${proposal.estimatedBudget.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                    ),
                  ],
                ),
                pw.Divider(height: 30, color: PdfColors.indigo100),
                pw.Row(
                  children: [
                    pw.Icon(const pw.IconData(0xe88f), size: 12, color: PdfColors.indigo400), // Info icon
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'This is an estimate. Final costs may vary depending on final scope adjustments.',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.indigo400),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 80),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 150, height: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 5),
                  pw.Text('Client Acceptance', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 150, height: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 5),
                  pw.Text('Agency Signature', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    // Share/Print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Proposal_${proposal.clientName.replaceAll(' ', '_')}.pdf',
    );
  }
}
