import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_card.dart';
import '../charts/interactive_bar_chart.dart';

class DailyEffortBanner extends StatelessWidget {
  final List<double> weeklyData; // 7 days, ending today
  final List<String> dayLabels;
  final double todayHours;

  const DailyEffortBanner({
    super.key, 
    required this.weeklyData,
    required this.dayLabels,
    required this.todayHours,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WEEKLY ACTIVITY', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${todayHours.toStringAsFixed(1)}h Today', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(width: 12),
                      Container(width: 1, height: 12, color: Colors.grey.withOpacity(0.3)),
                      const SizedBox(width: 12),
                      Text('${(weeklyData.reduce((a, b) => a + b) / 7).toStringAsFixed(1)}h avg', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.bar_chart, color: Colors.blue, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: InteractiveBarChart(
              dailyValues: weeklyData,
              barColor: Colors.grey.withOpacity(0.2),
              touchedColor: Colors.blue,
              dayLabels: dayLabels,
            ),
          ),
        ],
      ),
    );
  }
}
