import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/currency_service.dart';

class ProposalPdfGenerator {
  static Future<void> generateAndShow(Proposal proposal) async {
    final bytes = await generatePdf(proposal);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
  }

  static Future<Uint8List> generatePdf(Proposal proposal) async {
    final pdf = pw.Document();

    // Load branding assets
    final ByteData logoData = await rootBundle.load('assets/images/logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final pw.MemoryImage logo = pw.MemoryImage(logoBytes);

    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.poppinsRegular(),
      bold: await PdfGoogleFonts.poppinsBold(),
      italic: await PdfGoogleFonts.poppinsItalic(), 
    );

    // Style Specific Settings
    PdfColor primaryColor;
    PdfColor secondaryColor;
    
    switch (proposal.style) {
      case 'Creative':
        primaryColor = PdfColor.fromHex('#F59E0B'); // Amber
        secondaryColor = PdfColor.fromHex('#10B981'); // Emerald
        break;
      case 'Minimal':
        primaryColor = PdfColors.black;
        secondaryColor = PdfColors.grey700;
        break;
      case 'Corporate':
      default:
        primaryColor = PdfColor.fromHex('#6366F1'); // Indigo
        secondaryColor = PdfColor.fromHex('#312E81'); // Dark Indigo
    }

    // --- Cover Page ---
    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          theme: theme,
          margin: const pw.EdgeInsets.all(0),
        ),
        build: (context) {
          if (proposal.style == 'Minimal') {
              return _buildMinimalCover(proposal, logo, primaryColor, secondaryColor);
          } else if (proposal.style == 'Creative') {
              return _buildCreativeCover(proposal, logo, primaryColor, secondaryColor);
          }
          return _buildCorporateCover(proposal, logo, primaryColor, secondaryColor);
        },
      ),
    );

    // --- Content Page(s) ---
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          margin: const pw.EdgeInsets.all(50),
        ),
        header: (context) => _buildHeader(proposal, logo, primaryColor, secondaryColor),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.Text('Executive Summary', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: primaryColor)),
          pw.SizedBox(height: 15),
          pw.Text(
            proposal.description,
            style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.6, color: PdfColors.grey800),
          ),
          
          pw.SizedBox(height: 40),
          pw.Text('Timeline & Deliverables', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: primaryColor)),
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
                    decoration: pw.BoxDecoration(color: primaryColor, shape: pw.BoxShape.circle),
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
              color: PdfColor(primaryColor.red, primaryColor.green, primaryColor.blue, 0.05),
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColor(primaryColor.red, primaryColor.green, primaryColor.blue, 0.1)),
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
                        pw.Text('Estimated Investment', style: pw.TextStyle(fontSize: 12, color: primaryColor, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                        pw.Text('Full Project Deliverables', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey400)),
                      ],
                    ),
                    pw.Text(
                      '${CurrencyService.symbol}${proposal.estimatedBudget.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: primaryColor),
                    ),
                  ],
                ),
                pw.Divider(height: 30, color: PdfColors.grey300),
                pw.Row(
                  children: [
                    pw.Icon(const pw.IconData(0xe88f), size: 12, color: primaryColor), // Info icon
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'This is an estimate. Final costs may vary depending on final scope adjustments.',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
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

    return pdf.save();
  }

  static pw.Widget _buildCorporateCover(Proposal proposal, pw.MemoryImage logo, PdfColor primary, PdfColor secondary) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [secondary, primary],
        ),
      ),
      padding: const pw.EdgeInsets.all(60),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(height: 80, width: 80, child: pw.Image(logo)),
          pw.SizedBox(height: 40),
          pw.Text('BUSINESS PROPOSAL', style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 4)),
          pw.SizedBox(height: 20),
          pw.Text(proposal.projectTitle.toUpperCase(), style: pw.TextStyle(color: PdfColors.white, fontSize: 42, fontWeight: pw.FontWeight.bold, lineSpacing: 1.1)),
          pw.SizedBox(height: 20),
          pw.Container(width: 100, height: 4, color: PdfColors.white),
          pw.SizedBox(height: 60),
          pw.Text('PREPARED FOR', style: pw.TextStyle(color: PdfColor(1, 1, 1, 0.6), fontSize: 9, letterSpacing: 1)),
          pw.SizedBox(height: 4),
          pw.Text(proposal.clientName, style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Spacer(),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(DateFormat.yMMMMd().format(proposal.dateSent), style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                pw.Text('ID: ${proposal.id.substring(0, 8).toUpperCase()}', style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
              ]
          )
        ],
      ),
    );
  }

  static pw.Widget _buildCreativeCover(Proposal proposal, pw.MemoryImage logo, PdfColor primary, PdfColor secondary) {
      return pw.Stack(
        children: [
          pw.Positioned(
            right: -100, top: -100,
            child: pw.Container(width: 400, height: 400, decoration: pw.BoxDecoration(color: primary, shape: pw.BoxShape.circle)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(60),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(height: 60, width: 60, child: pw.Image(logo)),
                pw.SizedBox(height: 40),
                pw.Text('Proposal For', style: pw.TextStyle(fontSize: 18, color: secondary)),
                pw.Text(proposal.clientName, style: pw.TextStyle(fontSize: 48, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.SizedBox(height: 10),
                pw.Text(proposal.projectTitle, style: pw.TextStyle(fontSize: 24, color: primary, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 100),
                pw.Row(
                  children: [
                    pw.Container(width: 40, height: 2, color: secondary),
                    pw.SizedBox(width: 10),
                    pw.Text(DateFormat.yMMMMd().format(proposal.dateSent), style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
  }

  static pw.Widget _buildMinimalCover(Proposal proposal, pw.MemoryImage logo, PdfColor primary, PdfColor secondary) {
      return pw.Container(
        color: PdfColors.white,
        padding: const pw.EdgeInsets.all(80),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(height: 40, width: 40, child: pw.Image(logo)),
            pw.Spacer(),
            pw.Text(proposal.projectTitle, style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.normal, color: PdfColors.black)),
            pw.SizedBox(height: 10),
            pw.Text('Prepared for ${proposal.clientName}', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
            pw.SizedBox(height: 40),
            pw.Divider(color: PdfColors.black, thickness: 0.5),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(DateFormat.yMMMMd().format(proposal.dateSent), style: pw.TextStyle(fontSize: 10)),
                pw.Text('CONFIDENTIAL', style: pw.TextStyle(fontSize: 10, letterSpacing: 2)),
              ],
            ),
          ],
        ),
      );
  }

  static pw.Widget _buildHeader(Proposal proposal, pw.MemoryImage logo, PdfColor primary, PdfColor secondary) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(height: 30, width: 30, child: pw.Image(logo)),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('COMMAND CENTER', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primary, letterSpacing: 1)),
                  pw.Text('PROPOSAL FOR ${proposal.clientName.toUpperCase()}', style: pw.TextStyle(fontSize: 6, color: PdfColors.grey500)),
                ],
              ),
            ],
          ),
          pw.Text('PROPOSAL ID: #${proposal.id.substring(0, 8).toUpperCase()}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          pw.Text('Generated by Freelancer Command Center v3.0', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ],
      ),
    );
  }
}
