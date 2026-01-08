import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/currency_service.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Reports & Analytics', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Colors.white,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor ?? Colors.black,
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Invoice>('invoices').listenable(),
        builder: (context, Box<Invoice> invoiceBox, _) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<Proposal>('proposals').listenable(),
            builder: (context, Box<Proposal> proposalBox, _) {
               return ValueListenableBuilder(
                valueListenable: Hive.box<Project>('projects').listenable(),
                builder: (context, Box<Project> projectBox, _) {
                  
                  final invoices = invoiceBox.values.toList().cast<Invoice>();
                  final proposals = proposalBox.values.toList().cast<Proposal>();
                  final projects = projectBox.values.toList().cast<Project>();

                  // Metrics Calculation (Converted to Global)
                  final paidInvoices = invoices.where((i) => i.status == 'Paid').toList();
                  final totalConverted = paidInvoices.fold(0.0, (sum, i) => sum + CurrencyService.convert(i.amount, i.currency));
                  
                  final pendingConverted = invoices.where((i) => i.status == 'Pending').fold(0.0, (s, i) => s + CurrencyService.convert(i.amount, i.currency));
                  
                  final acceptedProposals = proposals.where((p) => p.status == 'Accepted').length;
                  final conversionRate = proposals.isEmpty ? 0.0 : acceptedProposals / proposals.length;
                  
                  final completedProjects = projects.where((p) => p.status == 'Completed').length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Key Metrics', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                         GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _buildMetricCard(context, 'Total Earnings', CurrencyService.format(totalConverted, CurrencyService.globalCurrency), Icons.payments, Colors.green),
                            _buildMetricCard(context, 'Total Pending', CurrencyService.format(pendingConverted, CurrencyService.globalCurrency), Icons.hourglass_full, Colors.orange),
                            _buildMetricCard(context, 'Conversion Rate', '${(conversionRate * 100).toStringAsFixed(1)}%', Icons.show_chart, Colors.purple),
                            _buildMetricCard(context, 'Completed Projs', '$completedProjects', Icons.task_alt, Colors.teal),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text('Income Distribution (By Client)', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          height: 250,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
                          child: _buildPieChart(paidInvoices),
                        ),
                        const SizedBox(height: 32),
                        Text('6-Month Trend', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          height: 250,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
                          child: _buildBarChart(paidInvoices),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                }
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(child: Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value, 
            style: GoogleFonts.poppins(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).textTheme.bodyLarge?.color
            )
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<Invoice> invoices) {
    final clientEarnings = <String, double>{};
    for (var inv in invoices) {
      final converted = CurrencyService.convert(inv.amount, inv.currency);
      clientEarnings[inv.clientName] = (clientEarnings[inv.clientName] ?? 0) + converted;
    }

    if (clientEarnings.isEmpty) {
      return Center(child: Text('No data available', style: GoogleFonts.poppins(color: Colors.grey)));
    }

    final List<Color> colors = [Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.red, Colors.teal];
    int colorIndex = 0;
    
    // For calculating total for percentage (not really accurate with mixed currencies, but we'll show label)
    // Actually, let's just show the amount and currency in the title.
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: clientEarnings.entries.map((e) {
          final color = colors[colorIndex % colors.length];
          colorIndex++;
          final invForClient = invoices.firstWhere((i) => i.clientName == e.key);
          final currency = invForClient.currency == 'INR' ? '₹' : '\$';
          
          return PieChartSectionData(
            color: color,
            value: e.value,
            title: '${e.key}\n${CurrencyService.symbol}${e.value.toStringAsFixed(0)}',
            radius: 50,
            titleStyle: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildBarChart(List<Invoice> invoices) {
    // Last 6 months simplified
    final now = DateTime.now();
    final Map<int, double> monthlyData = {}; // Month Index (0-11) -> Amount
    
    // Initialize last 6 months
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      monthlyData[month.month] = 0.0;
    }

    for (var inv in invoices) {
      if (inv.date.isAfter(DateTime(now.year, now.month - 6, 1))) {
         final converted = CurrencyService.convert(inv.amount, inv.currency);
         monthlyData[inv.date.month] = (monthlyData[inv.date.month] ?? 0) + converted;
      }
    }

    List<BarChartGroupData> barGroups = [];
    int x = 0;
    
    for (int i = 5; i >= 0; i--) {
       final d = DateTime(now.year, now.month - i, 1);
       final amount = monthlyData[d.month] ?? 0.0;
       barGroups.add(
         BarChartGroupData(
           x: x, 
           barRods: [BarChartRodData(toY: amount, color: Colors.blue, width: 16, borderRadius: BorderRadius.circular(4))]
         )
       );
       x++;
    }

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                 final d = DateTime(now.year, now.month - 5 + val.toInt(), 1);
                 return Text(DateFormat.MMM().format(d), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }
}
